group "default" {
    targets = [
        ### CUDA ###
        "py311-cuda1280-runtime-ubuntu2004",
    ]
}

target "py311-cuda1280-runtime-ubuntu2004" {
    dockerfile = "Dockerfile"
    contexts = {
        nushell = "./container-template/nushell"
        proxy = "./container-template/proxy"
        logo = "./container-template"
        scripts = "./container-template"
    }
    args = {
        BASE_IMAGE = "nvidia/cuda:12.8.0-runtime-ubuntu20.04"
        PYTHON_VERSION = "3.11"
    }
}