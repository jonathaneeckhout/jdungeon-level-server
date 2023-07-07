FROM ubuntu:22.04

# Set the working directory
WORKDIR /app

# Copy your Godot project to the container
COPY ./build/linux/ /app/

ENTRYPOINT ["/app/Jdungeon-level-server.x86_64", "--headless"]
