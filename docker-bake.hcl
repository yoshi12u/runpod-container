group "default" {
    targets = [
        ### CUDA ###
        "py311-cuda1280-runtime-ubuntu2004",
    ]
}

target "py311-cuda1280-runtime-ubuntu2004" {
    dockerfile = "Dockerfile"
    args = {
        BASE_IMAGE = "nvidia/cuda:12.4.1-devel-ubuntu22.04"
        PYTHON_VERSION = "3.11"
    }
}