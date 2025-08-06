# ComfyUI NVIDIA Docker Image

A production-ready Docker image for [ComfyUI](https://github.com/comfyanonymous/ComfyUI) with NVIDIA GPU support, optimized for various compute capabilities and pre-configured with essential custom nodes.

I got tired setting up ComfyUI again and again on different machines, and also wanted
a simple way to run several instances on a MultiGPU machine, so I wrote this Dockerfile.

It's really only tested on a 2x3090 and a single GH200. If you find it useful and use
it, I'd love to hear any feedbak you have.

I'm still learning ComfyUI so this image contains mostly the nodes I have used so far,
so if you have any requests for popular ones, I'm eager to hear and learn about them as
well as try to add support in the image, so feel free to open an issue.

## Features

- 🚀 **Multi-GPU Support**: Optimized builds for different NVIDIA compute capabilities
- 🎨 **Pre-installed Custom Nodes**: Essential ComfyUI extensions ready to use
- 🔧 **SageAttention 2.2**: Advanced attention mechanism for improved performance  
- 🐳 **Production Ready**: Based on NVIDIA's official PyTorch container
- ⚡ **Optimized Performance**: CUDA-optimized builds for maximum efficiency

## Supported NVIDIA GPUs

This image supports a wide range of NVIDIA GPUs with different compute capabilities:

### Current Generation (2024-2025)

| GPU Model | Architecture | Compute Capability | Docker Tag | Memory |
|-----------|--------------|-------------------|------------|---------|
| **RTX 50 Series (Blackwell)** |
| RTX 5090 | Blackwell | 12.0 | `sm120` | 32GB GDDR7 |
| RTX 5080 | Blackwell | 12.0 | `sm120` | 16GB GDDR7 |
| RTX 5070 Ti | Blackwell | 12.0 | `sm120` | 16GB GDDR7 |
| RTX 5070 | Blackwell | 12.0 | `sm120` | 12GB GDDR7 |
| **RTX 40 Series (Ada Lovelace)** |
| RTX 4090 | Ada Lovelace | 8.9 | `sm89` | 24GB GDDR6X |
| RTX 4080 | Ada Lovelace | 8.9 | `sm89` | 16GB GDDR6X |
| RTX 4070 Ti | Ada Lovelace | 8.9 | `sm89` | 12GB GDDR6X |
| RTX 4070 | Ada Lovelace | 8.9 | `sm89` | 12GB GDDR6 |
| RTX 4060 Ti | Ada Lovelace | 8.9 | `sm89` | 16GB/8GB GDDR6 |
| RTX 4060 | Ada Lovelace | 8.9 | `sm89` | 8GB GDDR6 |
| **RTX 30 Series (Ampere)** |
| RTX 3090 Ti | Ampere | 8.6 | `sm86` | 24GB GDDR6X |
| RTX 3090 | Ampere | 8.6 | `sm86` | 24GB GDDR6X |
| RTX 3080 Ti | Ampere | 8.6 | `sm86` | 12GB GDDR6X |
| RTX 3080 | Ampere | 8.6 | `sm86` | 12GB/10GB GDDR6X |
| RTX 3070 Ti | Ampere | 8.6 | `sm86` | 8GB GDDR6X |
| RTX 3070 | Ampere | 8.6 | `sm86` | 8GB GDDR6 |
| RTX 3060 Ti | Ampere | 8.6 | `sm86` | 8GB GDDR6 |
| RTX 3060 | Ampere | 8.6 | `sm86` | 12GB/8GB GDDR6 |

### Professional & Data Center GPUs

| GPU Model | Architecture | Compute Capability | Docker Tag | Memory |
|-----------|--------------|-------------------|------------|---------|
| **Hopper Architecture** |
| H200 | Hopper | 9.0 | `sm90` | 141GB HBM3e |
| H100 SXM5 | Hopper | 9.0 | `sm90` | 80GB HBM3 |
| H100 PCIe | Hopper | 9.0 | `sm90` | 80GB HBM3 |
| GH200 | Hopper | 9.0 | `sm90` | 96GB HBM3 |
| **Ampere Data Center** |
| A100 SXM4 | Ampere | 8.0 | `sm80` | 80GB/40GB HBM2e |
| A100 PCIe | Ampere | 8.0 | `sm80` | 80GB/40GB HBM2e |
| A800 | Ampere | 8.0 | `sm80` | 80GB/40GB HBM2e |
| **Ada Lovelace Professional** |
| RTX 6000 Ada | Ada Lovelace | 8.9 | `sm89` | 48GB GDDR6 |
| RTX 5000 Ada | Ada Lovelace | 8.9 | `sm89` | 32GB GDDR6 |
| RTX 4500 Ada | Ada Lovelace | 8.9 | `sm89` | 24GB GDDR6 |
| RTX 4000 Ada | Ada Lovelace | 8.9 | `sm89` | 20GB GDDR6 |
| L40 | Ada Lovelace | 8.9 | `sm89` | 48GB GDDR6 |
| L4 | Ada Lovelace | 8.9 | `sm89` | 24GB GDDR6 |
| **Ampere Professional** |
| RTX A6000 | Ampere | 8.6 | `sm86` | 48GB GDDR6 |
| RTX A5000 | Ampere | 8.6 | `sm86` | 24GB GDDR6 |
| RTX A4000 | Ampere | 8.6 | `sm86` | 16GB GDDR6 |
| RTX A2000 | Ampere | 8.6 | `sm86` | 12GB GDDR6 |
| A40 | Ampere | 8.6 | `sm86` | 48GB GDDR6 |

### Legacy GPUs (Still Supported)

| GPU Model | Architecture | Compute Capability | Docker Tag | Notes |
|-----------|--------------|-------------------|------------|-------|
| **Turing** |
| RTX 2080 Ti | Turing | 7.5 | Not supported | Legacy |
| RTX 2080 | Turing | 7.5 | Not supported | Legacy |
| RTX 2070 | Turing | 7.5 | Not supported | Legacy |
| RTX 2060 | Turing | 7.5 | Not supported | Legacy |
| **Volta** |
| Tesla V100 | Volta | 7.0 | Not supported | Legacy |
| Titan V | Volta | 7.0 | Not supported | Legacy |

## Quick Start

### 0. Clone this repo and update submodules for custom nodes
```
git clone https://github.com/idoru/comfyui-nvidia-image.git
cd comfyui-nvidia-image
git submodule update --init
```
### 1. Choose Your GPU's Docker Tag

Find your GPU in the compatibility table above and note the corresponding Docker tag (e.g., `sm86` for RTX 3090, `sm89` for RTX 4090, `sm120` for RTX 5090).

### 2. Build the Image

```bash
# For RTX 3090 (Compute Capability 8.6)
make sm86

# For RTX 4090 (Compute Capability 8.9) 
make sm89

# For RTX 5090 (Compute Capability 12.0)
make sm120

# Build all supported versions
make all
```

### 3. Run with Docker Compose

```bash
# Edit docker-compose.yaml to use your GPU's tag and right number of instances with unique ports
docker-compose up
```

### 4. Run Manually

```bash
docker run --gpus all --ipc=host \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  -p 8188:8188 \
  -v ./models:/home/ubuntu/ComfyUI/models \
  -v ./output:/home/ubuntu/ComfyUI/output \
  comfy-skcfi:sm86
```

## Build Arguments

- `COMPUTE_CAPABILITY`: Target compute capability (default: 9.0)

Example:
```bash
docker build --build-arg COMPUTE_CAPABILITY=8.6 -t comfy-skcfi:sm86 .
```

## Included Custom Nodes

The image comes pre-configured with essential ComfyUI custom nodes:

- **ComfyUI-Manager**: Node manager and installer
- **ComfyUI-Advanced-ControlNet**: Advanced ControlNet implementations
- **ComfyUI-Image-Saver**: Enhanced image saving capabilities
- **ComfyUI-Impact-Pack**: Detailing and enhancement tools
- **ComfyUI-KJNodes**: Various utility nodes
- **ComfyUI-VideoHelperSuite**: Video processing tools
- **comfyui-essentials**: Essential utility nodes
- And many more...

See the `custom_nodes/` directory for the complete list. Open an issue or PR
if you would like to see a popular custom node.

## Configuration

### Environment Variables

- `PORT`: Server port (default: 8188)
- `PYTORCH_CUDA_ALLOC_CONF`: CUDA memory allocation (default: expandable_segments:True)
- `CUDA_VISIBLE_DEVICES`: Control GPU visibility

### Runtime Flags

The container starts ComfyUI with optimized flags:
- `--fast`: Enable fast mode
- `--use-sage-attention`: Use SageAttention 2.2 for improved performance
- `--listen 0.0.0.0`: Listen on all interfaces
- `--port ${PORT}`: Use configured port

## Multi-GPU Setup

Use the provided `docker-compose.yaml` for multi-GPU setups to share model directory for disk space.

## Performance Optimization

### Memory Settings

The container is configured with NVIDIA's recommended settings:
- `--ipc=host`: Shared memory optimization
- `--ulimit memlock=-1`: Unlimited locked memory
- `--ulimit stack=67108864`: Optimized stack size

### CUDA Optimization

- **SageAttention 2.2**: Compiled for your specific compute capability
- **PyTorch**: Official NVIDIA container with optimized PyTorch build
- **Expandable Segments**: Efficient CUDA memory management

## Troubleshooting

### Common Issues

1. **GPU Not Detected**
   - Ensure NVIDIA drivers are installed on host
   - Verify `nvidia-container-toolkit` is installed
   - Check `docker run --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi`

2. **Out of Memory Errors**
   - Reduce batch size in ComfyUI
   - Enable model offloading to CPU
   - Use lower precision models

3. **Slow Performance**
   - Verify correct compute capability tag
   - Check GPU utilization with `nvidia-smi`
   - Ensure sufficient system RAM

### Build Issues

If custom node installation fails:
- Check `custom-node-install-receipt.txt` in the container
- Some nodes may require additional dependencies

## Architecture Details

### Base Container

- **Base**: `nvcr.io/nvidia/pytorch:25.06-py3`
- **CUDA Version**: Compatible with latest NVIDIA drivers
- **PyTorch**: Optimized NVIDIA build with CUDA support

### Build Process

1. **Base Setup**: Install system dependencies
2. **TorchAudio**: Build from source with CUDA support  
3. **ComfyUI**: Install core application and dependencies
4. **SageAttention**: Compile for target compute capability
5. **Custom Nodes**: Install and configure extensions
6. **SAM2**: Build Segment Anything 2 from source

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

## License

This Docker configuration is provided under the MIT License. Individual components may have their own licenses:

- ComfyUI: GPL-3.0 License
- Custom nodes: Various licenses (see individual node directories)
- NVIDIA containers: NVIDIA Deep Learning Container License

## Support

For issues related to:
- **ComfyUI**: Visit the [ComfyUI repository](https://github.com/comfyanonymous/ComfyUI)
- **Custom Nodes**: Check individual node repositories
- **Docker Image**: Open an issue in this repository

## References

- [NVIDIA PyTorch Container](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch)
- [NVIDIA Deep Learning Framework Support Matrix](https://docs.nvidia.com/deeplearning/frameworks/support-matrix/index.html)  
- [CUDA GPU Compute Capabilities](https://developer.nvidia.com/cuda-gpus)
- [SM Architecture Matching Guide](https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/)
