FROM nvidia/cuda:13.0.0-devel-ubuntu24.04 AS base
#Set compute capability accordingly.
#  8.0 e.g. A100.
#  8.6 e.g. 3090.
#  8.9 e.g. 4090.
#  9.0 e.g. H100, GH200
#  12.0 e.g. B200, 5090
#See https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/ for more.
ARG COMPUTE_CAPABILITY="9.0"
ENV COMPUTE_CAPABILITY=${COMPUTE_CAPABILITY}
# USER root is default for nvidia/cuda images, but explicit declaration causes
# "unable to find user root" in some Docker-in-Docker setups. Omit it.
RUN apt update && apt upgrade -y && apt install -y git curl libgl1 libopengl0 libglx0 ninja-build fonts-roboto libcairo2-dev pkg-config python3-dev build-essential && apt-get clean && \
  rm -rf /var/lib/apt/lists/*

USER ubuntu
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/ubuntu/venv/bin:/home/ubuntu/.local/bin:${PATH}"

#Setup comfy via comfy-cli; build SageAttention 2.2 from source against the venv torch
FROM base AS comfy-skcfi

ENV USE_NINJA=1 \
    TORCH_CUDA_ARCH_LIST=${COMPUTE_CAPABILITY} \
    EXT_PARALLEL=4 \
    NVCC_APPEND_FLAGS="--threads 8" \
    MAX_JOBS=0 \
    DEBUG=0

#Create the venv, install comfy-cli + the cu130 torch wheels we want comfy to use
RUN uv venv -p 3.13 /home/ubuntu/venv && . /home/ubuntu/venv/bin/activate && \
  uv pip install -U pip packaging nvidia-ml-py PyOpenGL PyOpenGL_accelerate soundfile comfy-cli && \
  uv pip uninstall torch torchvision torchaudio torchtext torchdata && \
  uv pip install --index-url "https://download.pytorch.org/whl/cu130" \
    "torch" "torchvision" "torchaudio"

#SageAttention 2.2 — needs a per-CC patched setup.py, not pip-resolvable
RUN cd /home/ubuntu && git clone https://github.com/thu-ml/SageAttention.git && \
  cd /home/ubuntu/SageAttention && sed -i 's/^compute_capabilities = set()/compute_capabilities = {"'${COMPUTE_CAPABILITY}'"}/' setup.py && \
  . /home/ubuntu/venv/bin/activate && uv pip install -e . --no-build-isolation

#sam2 — special build, not a ComfyUI custom node
RUN cd /home/ubuntu && . /home/ubuntu/venv/bin/activate && \
  git clone https://github.com/facebookresearch/sam2 && cd sam2 && uv pip install -e . --no-build-isolation

#ComfyUI install via comfy-cli (replaces manual git clone of ComfyUI + ComfyUI-Manager).
#--skip-torch-or-directml leaves the cu130 wheels we just installed alone.
#--fast-deps uses uv for ComfyUI core requirements; it writes override.txt into
#cwd, so cd somewhere writable first.
RUN cd /home/ubuntu && . /home/ubuntu/venv/bin/activate && \
  comfy --skip-prompt --no-enable-telemetry --workspace=/home/ubuntu/ComfyUI install \
    --nvidia --skip-torch-or-directml --fast-deps

#Restore custom nodes from snapshot. cm-cli clones each node and runs
#`pip install -r requirements.txt` + `python install.py` per-node. We don't
#use --uv-compile: it does a post-pass `uv pip compile` across all 49 nodes
#which (a) rejects valid `git+https://...` deps used by Impact-Pack /
#was-node-suite and (b) trips on ComfyUI-Copilot's `sqlalchemy<2.0` pin.
COPY --chown=ubuntu:ubuntu snapshot.json /home/ubuntu/snapshot.json
RUN cd /home/ubuntu && . /home/ubuntu/venv/bin/activate && \
  comfy --skip-prompt --no-enable-telemetry --workspace=/home/ubuntu/ComfyUI \
    node restore-snapshot /home/ubuntu/snapshot.json

# ComfyUI-Manager — restore-snapshot skips it if comfy install already placed
# a different version, so clone explicitly to guarantee it's present.
RUN cd /home/ubuntu/ComfyUI/custom_nodes && \
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
  cd ComfyUI-Manager && \
  . /home/ubuntu/venv/bin/activate && \
  pip install -r requirements.txt

# ComfyUI-Workflow-Models-Downloader — server-side model downloads from workflow
# metadata (properties.models). ComfyUI core's "Missing Models" UI only opens
# browser download links (saves to client, not server). ComfyUI-Manager's model
# download is whitelist-only (model-list.json). This node fills the gap: it
# scans loaded workflows for missing models and downloads them into the correct
# server-side folders from HuggingFace/CivitAI/direct URLs.
RUN cd /home/ubuntu/ComfyUI/custom_nodes && \
  git clone https://github.com/slahiri/ComfyUI-Workflow-Models-Downloader.git && \
  cd ComfyUI-Workflow-Models-Downloader && \
  . /home/ubuntu/venv/bin/activate && \
  pip install -r requirements.txt

# Force sqlalchemy back to 2.x — ComfyUI core needs it and ComfyUI-Copilot's
# requirements.txt downgrades it to <2.0 during the per-node install above.
RUN . /home/ubuntu/venv/bin/activate && uv pip install -U 'sqlalchemy>=2.0'

# ComfyUI-Frame-Interpolation has a post-install model fetch not covered by requirements.txt
RUN . /home/ubuntu/venv/bin/activate && \
  cd /home/ubuntu/ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation && python install.py

# ComfyUI-LTXVideo imports 'pad' from kornia.geometry.transform.pyramid but
# that function doesn't exist in any released kornia version (latest 0.8.3).
# The file already has `import torch.nn.functional as F`, so just remove `pad`
# from the kornia import and switch the two bare `pad(` calls to `F.pad(`.
RUN sed -i '/^    pad,$/d' \
    /home/ubuntu/ComfyUI/custom_nodes/ComfyUI-LTXVideo/pyramid_blending.py && \
  sed -i 's/^        image = pad(/        image = F.pad(/; s/^        images = pad(/        images = F.pad(/' \
    /home/ubuntu/ComfyUI/custom_nodes/ComfyUI-LTXVideo/pyramid_blending.py


ENV PORT=8188
ENV PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
USER ubuntu
WORKDIR /home/ubuntu/ComfyUI
CMD python main.py --lowvram --enable-manager-legacy-ui --listen 0.0.0.0 --port ${PORT}
