# ==============================================================================
# STAGE 1: Build BeaEngine (Native Library for ConfuserEx control flow cleaning)
# ==============================================================================
FROM ubuntu:22.04 AS beaengine-builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    cmake \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY native/BeaEngine ./native/BeaEngine

RUN cmake -S native/BeaEngine -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build \
    && mkdir -p /app \
    && cp build/bin/libBeaEngine.so /app/libBeaEngine.so

# ==============================================================================
# STAGE 2: Build de4dotEx (.NET 10 Cross-Platform Release)
# ==============================================================================
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS dotnet-builder
WORKDIR /src

# Copy all files to build
COPY . .

# Publish both de4dot and the de4dot.mcp server targeting net10.0
RUN dotnet publish -c Release -f net10.0 -o /app/publish/de4dot src/de4dot/de4dot.csproj
RUN dotnet publish -c Release -f net10.0 -o /app/publish/mcp src/de4dot.mcp/de4dot.mcp.csproj
RUN rm -rf /app/publish/**/*.pdb /app/publish/**/*.xml

# ==============================================================================
# STAGE 3: Final Runtime Image (.NET 10 on Ubuntu / Runtime)
# ==============================================================================
FROM mcr.microsoft.com/dotnet/runtime:10.0 AS runtime
WORKDIR /app

# Install native dependencies required for execution (e.g. globalization, bash)
RUN apt-get update && apt-get install -y \
    libicu-dev \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Copy de4dot and MCP published folders
COPY --from=dotnet-builder /app/publish/de4dot ./de4dot
COPY --from=dotnet-builder /app/publish/mcp ./mcp

# Copy compiled libBeaEngine.so from Stage 1 standardized path to system libraries & register
COPY --from=beaengine-builder /app/libBeaEngine.so /usr/local/lib/libBeaEngine.so
RUN ldconfig

# Create symlinks for global accessibility
RUN ln -s /app/de4dot/de4dot /usr/local/bin/de4dot && \
    ln -s /app/mcp/de4dot.mcp /usr/local/bin/de4dot-mcp

# Create a unified entrypoint script inside the final image
RUN printf '#!/bin/bash\n\
if [ "$1" = "--mcp" ] || [ "$1" = "-mcp" ]; then\n\
    shift\n\
    exec /app/mcp/de4dot.mcp "$@"\n\
else\n\
    exec /app/de4dot/de4dot "$@"\n\
fi\n' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Expose HTTP port 8080 (for MCP Web API mode)
EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["--help"]
