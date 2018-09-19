docker build -t webapp . && \
docker run --name webapp1 -p 8080:8080 -d webapp
