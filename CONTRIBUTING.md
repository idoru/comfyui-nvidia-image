# Contributing to ComfyUI NVIDIA Docker Image

Thank you for your interest in contributing to the ComfyUI NVIDIA Docker Image project! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)
- [Build and Testing](#build-and-testing)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to a code of conduct adapted from the [Contributor Covenant](https://www.contributor-covenant.org/). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

### Our Standards

Examples of behavior that contributes to creating a positive environment include:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

## Getting Started

### Prerequisites

Before contributing, ensure you have:
- Docker installed and configured
- NVIDIA Docker runtime (`nvidia-container-toolkit`)
- Git for version control
- Basic understanding of Docker, CUDA, and ComfyUI

### Development Environment

1. **Fork the Repository**
   ```bash
   git clone https://github.com/yourusername/comfyui-nvidia-image.git
   cd comfyui-nvidia-image
   ```

2. **Verify Docker Setup**
   ```bash
   docker run --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi
   ```

3. **Test Build Process**
   ```bash
   make sm86  # or your GPU's compute capability
   ```

## Contributing Guidelines

### Types of Contributions

We welcome several types of contributions:

1. **Bug Reports**: Help us identify and fix issues
2. **Feature Requests**: Suggest new functionality or improvements
3. **Code Contributions**: Submit bug fixes, features, or optimizations
4. **Documentation**: Improve README, guides, or inline documentation
5. **Testing**: Help test builds on different GPU configurations
6. **Custom Node Integration**: Add support for new ComfyUI custom nodes

### Branch Naming Convention

Use descriptive branch names with prefixes:
- `feature/`: New features or enhancements
- `bugfix/`: Bug fixes
- `docs/`: Documentation updates
- `test/`: Testing improvements
- `refactor/`: Code refactoring

Examples:
```
feature/add-rtx-5090-support
bugfix/memory-leak-sage-attention
docs/update-gpu-compatibility-table
test/multi-gpu-validation
```

### Commit Message Format

Follow conventional commit format:
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions or modifications
- `chore`: Build process or auxiliary tool changes

Examples:
```
feat(docker): add support for RTX 5090 compute capability 12.0

fix(build): resolve SageAttention compilation error on sm89

docs(readme): update GPU compatibility matrix with RTX 50 series
```

## Pull Request Process

### Before Submitting

1. **Test Your Changes**
   - Build the Docker image for your target compute capability
   - Test basic ComfyUI functionality
   - Verify custom nodes load correctly
   - Check for memory leaks or performance regressions

2. **Update Documentation**
   - Update README.md if adding GPU support
   - Add or update comments in Dockerfile
   - Update CONTRIBUTING.md if changing development process

3. **Code Quality**
   - Follow existing code style and patterns
   - Ensure Dockerfile follows best practices
   - Minimize image size where possible
   - Use multi-stage builds effectively

### Submission Checklist

- [ ] Branch is up-to-date with main branch
- [ ] Changes build successfully for target compute capabilities
- [ ] Documentation is updated (README, comments, etc.)
- [ ] Commit messages follow conventional format
- [ ] Changes are tested on actual hardware (if possible)
- [ ] No sensitive information (API keys, personal data) included

### Pull Request Template

```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Built and tested on GPU: [GPU model]
- [ ] Verified ComfyUI starts correctly
- [ ] Tested custom node functionality
- [ ] Checked memory usage and performance

## GPU Compatibility
- [ ] Tested on compute capability: [X.X]
- [ ] Updated GPU compatibility table
- [ ] Verified Docker tag naming

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
```

## Issue Guidelines

### Bug Reports

When reporting bugs, include:

1. **Environment Information**
   - Host OS and version
   - Docker version
   - NVIDIA driver version
   - GPU model and compute capability
   - Docker image tag used

2. **Steps to Reproduce**
   - Exact commands used
   - Configuration files
   - Input data (if applicable)

3. **Expected vs Actual Behavior**
   - What you expected to happen
   - What actually happened
   - Screenshots or logs if helpful

4. **Error Messages**
   - Complete error messages
   - Relevant log outputs
   - Stack traces

### Feature Requests

For feature requests, provide:

1. **Use Case**: Describe the problem you're trying to solve
2. **Proposed Solution**: Your idea for addressing the issue
3. **Alternatives**: Other approaches you've considered
4. **Additional Context**: Screenshots, examples, or references

## Build and Testing

### Building Images

```bash
# Build for specific compute capability
make sm86    # RTX 3090
make sm89    # RTX 4090
make sm90    # H100
make sm120   # RTX 5090

# Build all supported versions
make all

# Custom build
docker build --build-arg COMPUTE_CAPABILITY=8.6 -t comfy-skcfi:sm86 .
```

### Testing Guidelines

1. **Basic Functionality**
   ```bash
   docker run --gpus all -p 8188:8188 comfy-skcfi:sm86
   # Verify ComfyUI web interface loads
   ```

2. **Custom Node Testing**
   - Verify all custom nodes load without errors
   - Test representative workflows
   - Check for Python import errors

3. **Performance Testing**
   - Monitor GPU memory usage
   - Test with various batch sizes
   - Compare performance with base ComfyUI

4. **Multi-GPU Testing**
   ```bash
   docker-compose up
   # Verify both instances start correctly
   ```

### Automated Testing

We encourage adding automated tests for:
- Docker build process
- Container startup validation
- Custom node loading
- Basic workflow execution

## Documentation

### Documentation Standards

- Use clear, concise language
- Include code examples where helpful
- Keep GPU compatibility table updated
- Link to relevant external resources

### Areas Needing Documentation

- GPU-specific optimizations
- Custom node integration process
- Troubleshooting common issues
- Performance tuning guidelines

## Release Process

1. **Version Tagging**: Use semantic versioning (v1.0.0)
2. **Release Notes**: Document changes, new GPU support, breaking changes
3. **Docker Hub**: Update published images
4. **Documentation**: Ensure all docs are current

## Getting Help

- **General Questions**: Open a discussion on GitHub
- **Bug Reports**: Use the issue tracker
- **Development Chat**: Join our community channels
- **Documentation**: Check the README and wiki

## Recognition

Contributors will be acknowledged in:
- README.md contributors section
- Release notes for significant contributions
- Git commit history

Thank you for contributing to the ComfyUI NVIDIA Docker Image project!