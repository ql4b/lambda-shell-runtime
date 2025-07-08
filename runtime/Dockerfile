FROM public.ecr.aws/lambda/provided:al2023

# Set the working directory
WORKDIR /var/task

# Copy bootstrap and handler files
COPY bootstrap /var/runtime/bootstrap
COPY handler.sh /var/task/handler.sh

# Ensure bootstrap is executable
RUN chmod +x /var/runtime/bootstrap

# Optional: copy additional CLI tools or libraries
# COPY bin/ /var/task/bin/
# ENV PATH="/var/task/bin:${PATH}"

# Set Lambda bootstrap as entrypoint
ENTRYPOINT ["/var/runtime/bootstrap"]
