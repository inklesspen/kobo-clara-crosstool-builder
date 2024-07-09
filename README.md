The Dockerfile in this directory will build a cross-compiling toolchain for Kobo's Clara series of e-ink devices.

(Specifically, it is known to generate binaries compatible with the Clara HD and Clara 2E. The binaries may or may not run on the new Clara Color and Clara B&W devices.)

It is based on pgaskin's [NickelTC](https://github.com/pgaskin/NickelTC), but does not attempt to build any Qt-related tooling, and it uses a modern release of crosstool-ng instead of NiLuJe's fork.

To use: `docker buildx build --platform=linux/arm64 . --output type=local,dest=.`

This produces a file named `arm-kobo-linux-gnueabihf.tar` in the current directory; consult the [`buildx build` docs](https://docs.docker.com/reference/cli/docker/buildx/build/#output) for other options. For example, you could save the build as a tagged container image, then `COPY` the tarball into another container for use there.

You can change the platform to `linux/amd64` for x86_64 architectures, or `linux/arm/v7` for 32-bit ARM. [Other platforms supported by Docker](https://docs.docker.com/build/building/multi-platform/) may also work, but have not been tested.
