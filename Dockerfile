FROM nvidia/cuda:13.0.1-devel-ubuntu24.04 AS base
#Set compute capability accordingly.
#  8.0 e.g. A100.
#  8.6 e.g. 3090.
#  8.9 e.g. 4090.
#  9.0 e.g. H100, GH200
#  12.0 e.g. B200, 5090
#See https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/ for more.
ARG COMPUTE_CAPABILITY="9.0"
ENV COMPUTE_CAPABILITY=${COMPUTE_CAPABILITY}
USER root
RUN apt update && apt upgrade -y && apt install -y git curl libgl1 libopengl0 libglx0 ninja-build fonts-roboto libcairo2-dev pkg-config python3-dev build-essential && apt-get clean && \
  rm -rf /var/lib/apt/lists/*

USER ubuntu
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/ubuntu/venv/bin:/home/ubuntu/.local/bin:${PATH}"

#Setup comfy and SageAttention 2.2; stay on numpy<2 packaging<25 to avoid conflicts
FROM base AS comfy-skcfi

#Setup uv venv, CUDA and SageAttention
ENV USE_NINJA=1 \
    TORCH_CUDA_ARCH_LIST=${COMPUTE_CAPABILITY} \
    EXT_PARALLEL=4 \
    NVCC_APPEND_FLAGS="--threads 8" \
    MAX_JOBS=0 \
    DEBUG=0

RUN uv venv /home/ubuntu/venv && . /home/ubuntu/venv/bin/activate && \
  uv pip install -U pip packaging nvidia-ml-py PyOpenGL PyOpenGL_accelerate && \
  uv pip uninstall torch torchvision torchaudio torchtext torchdata && \
  uv pip install --index-url "https://download.pytorch.org/whl/nightly/cu130" \
    "torch" "torchvision" "torchaudio" && \
  cd /home/ubuntu && git clone https://github.com/thu-ml/SageAttention.git && \
  cd /home/ubuntu/SageAttention && sed -i 's/^compute_capabilities = set()/compute_capabilities = {"'"${COMPUTE_CAPABILITY}"'"}/' setup.py && uv pip install -e . --no-build-isolation

COPY --chown=ubuntu:ubuntu custom_nodes/ /home/ubuntu/custom_nodes/

#Fallback to onnxruntime on non-darwin ARM64 (no gpu package)
#Dont install jetson-stats, crystools assumes we're on Jetson on arm64

RUN  cd /home/ubuntu && . /home/ubuntu/venv/bin/activate && \
  git clone https://github.com/facebookresearch/sam2 && cd sam2 && uv pip install -e . --no-build-isolation && \
  cd /home/ubuntu && \
  git clone https://github.com/comfyanonymous/ComfyUI.git && \
  cd ComfyUI && uv pip install -r requirements.txt && \
  cd /home/ubuntu/ComfyUI/custom_nodes && mv /home/ubuntu/custom_nodes/* ./ && git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager && \
  cd /home/ubuntu/ComfyUI/custom_nodes && sed -i.onnxbak 's/onnxruntime-gpu$/onnxruntime\nonnxruntime-gpu; sys_platform != "darwin" and platform_machine == "x86_64"/' */requirements.txt && \
  sed -i.jetsonbak '/^[[:space:]]*jetson-stats;.*/d' */requirements.txt

RUN cd /home/ubuntu/ComfyUI/custom_nodes && . /home/ubuntu/venv/bin/activate && \
  set -e ; \
  for dir in */ ; do \
    if [ -f "/home/ubuntu/ComfyUI/custom_nodes/${dir}/requirements.txt" ]; then \
      cd "/home/ubuntu/ComfyUI/custom_nodes/${dir}" && uv pip install -r requirements.txt \
      || { echo "FAILED: pip install failed in $dir" >&2; exit 1; } \
    fi ; \
  done > /home/ubuntu/ComfyUI/custom-node-install-receipt.txt

RUN cd /home/ubuntu/ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation && python install.py

ENV PORT=8188
ENV PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
USER ubuntu
WORKDIR /home/ubuntu/ComfyUI
CMD python main.py --fast --listen 0.0.0.0 --port ${PORT}
