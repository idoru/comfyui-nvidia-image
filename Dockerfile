FROM nvcr.io/nvidia/pytorch:25.09-py3 AS base
#From Nvidia, recommended to run with gpu setings:
#docker run --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 -it nvcr.io/nvidia/pytorch:25.06-py3
#More info:
#    https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch
#    https://docs.nvidia.com/deeplearning/frameworks/support-matrix/index.html

#Set compute capability accordingly.
#  8.0 e.g. A100.
#  8.6 e.g. 3090.
#  8.9 e.g. 4090.
#  9.0 e.g. H100.
#  12.0 e.g. B200, 5090
#See https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/ for more.
ARG COMPUTE_CAPABILITY="9.0"
ENV COMPUTE_CAPABILITY=${COMPUTE_CAPABILITY}
USER root
RUN apt update && apt upgrade -y && apt install -y git curl libgl1 fonts-roboto libcairo2-dev pkg-config python3-dev build-essential && apt-get clean && \
  rm -rf /var/lib/apt/lists/*

USER ubuntu
ENV PATH="/home/ubuntu/.local/bin:${PATH}"

#Build and torchaudio because it isn't on the pytorch image
FROM base AS torchaudio 

RUN cd /home/ubuntu && \
  git clone --depth 1 --branch "release/2.9" https://github.com/pytorch/audio.git ./torchaudio && cd ./torchaudio && \
  export PYTORCH_VERSION="$(pip show torch | grep ^Version | awk '{print $2}')" && \
  export TORCH_CUDA_ARCH_LIST="${COMPUTE_CAPABILITY}" USE_CUDA=1 USE_FFMPEG=1 BUILD_SOX=1 && \
  pip wheel . --no-build-isolation -v --no-deps -w /tmp/wheels

#Setup comfy and SageAttention 2.2; stay on numpy<2 packaging<25 to avoid conflicts
FROM base AS comfy-skcfi
COPY --from=torchaudio /tmp/wheels/*.whl /home/ubuntu
RUN cd /home/ubuntu && pip install /home/ubuntu/*.whl && git clone https://github.com/comfyanonymous/ComfyUI.git && \
  cd /home/ubuntu/ComfyUI && echo 'numpy<2' > constraints.txt && echo 'packaging<25' >> constraints.txt && pip install -c constraints.txt -r requirements.txt && \
  cd /home/ubuntu/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager && \
  cd /home/ubuntu && git clone https://github.com/thu-ml/SageAttention.git && \
  cd /home/ubuntu/SageAttention && sed -i 's/^compute_capabilities = set()/compute_capabilities = {"'"${COMPUTE_CAPABILITY}"'"}/' setup.py && pip install -e .

COPY --chown=ubuntu:ubuntu custom_nodes/ /home/ubuntu/ComfyUI/custom_nodes/

#Tweak deps and install Segment anything 2 ourselves as it won't build against NVIDIA's custom pytroch version label.
#Tweak Impack Pack so it doesn't try to install SAM2 from source.
#Fallback to onnxruntime on ARM64 (no gpu package)
#Remove jetson-stats, crystools assumes we're on Jetson on arm64
RUN cd /home/ubuntu && \
  git clone https://github.com/facebookresearch/sam2 && cd sam2 && sed -i.bak '/^[[:space:]]*"torch[=<>][^"]*".*/d' pyproject.toml setup.py && pip install -e . && \
  cd /home/ubuntu/ComfyUI/custom_nodes/ComfyUI-Impact-Pack && sed -i.bak '/^.*facebookresearch\/sam2.*$/d' requirements.txt && \
  cd /home/ubuntu/ComfyUI/custom_nodes && sed -i.onnxbak 's/onnxruntime-gpu$/onnxruntime\nonnxruntime-gpu; sys_platform != "darwin" and platform_machine == "x86_64"/' */requirements.txt && \
  sed -i.jetsonbak '/^[[:space:]]*jetson-stats;.*/d' */requirements.txt

RUN cd /home/ubuntu/ComfyUI/custom_nodes && \
  set -e ; \
  cd ComfyUI-Frame-Interpolation && python install.py && cd .. && \
  for dir in ./*/ ; do \
    if [ -f "$dir/requirements.txt" ]; then \
      pushd "$dir" && pip install -c ../../constraints.txt -r requirements.txt && popd \
      || { echo "FAILED: pip install failed in $dir" >&2; exit 1; } \
    fi ; \
  done > /home/ubuntu/ComfyUI/custom-node-install-receipt.txt

ENV PORT=8188
ENV PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
USER ubuntu
WORKDIR /home/ubuntu/ComfyUI
CMD python main.py --fast --use-sage-attention --listen 0.0.0.0 --port ${PORT}
