variable "PUBLISHER" {
    default = "yoshi12u"
}

group "default" {
    targets = [
        ### CUDA ###
        "py311-cuda1280-runtime-ubuntu2004",
    ]
}



target "py311-cuda1280-runtime-ubuntu2004" {
    dockerfile = "Dockerfile"
    tags = ["${PUBLISHER}/runpod-container:python3.11-cuda12.8.0-runtime-ubuntu20.04"]
    contexts = {
        scripts = "../../container-template"
        proxy = "../../container-template/proxy"
        logo = "../../container-template"
        nushell = "../../container-template/nushell"
    }
    args = {
        BASE_IMAGE = "nvidia/cuda:12.8.0-runtime-ubuntu20.04"
        PYTHON_VERSION = "3.11"
    }
}