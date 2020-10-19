This folder is for adding build scripts for various architectures to apply quick fixes for building on other architectures.

To use you would create a subfolder (ie `armhf`, `amd64`, `arm64`) then place an appropriate shell script in that folder to build.

This directory was added to enable satisfying dependencies that aren't automatically satisfied by the distro (for ex: mongodb on armhf)
