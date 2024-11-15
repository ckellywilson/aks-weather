# Setting Up the Project with Dev Containers

## Prerequisites

- Docker Desktop
- Visual Studio Code
- Remote - Containers extension for Visual Studio Code

## Instructions for Windows

1. **Install Docker Desktop**:
    - Download and install Docker Desktop from [Docker's official website](https://www.docker.com/products/docker-desktop).
    - Ensure Docker is running.

2. **Install Visual Studio Code**:
    - Download and install Visual Studio Code from [Visual Studio Code's official website](https://code.visualstudio.com/).

3. **Install Remote - Containers Extension**:
    - Open Visual Studio Code.
    - Go to the Extensions view by clicking on the Extensions icon in the Activity Bar on the side of the window.
    - Search for `Remote - Containers` and install it.

4. **Clone the Repository**:
    - Open a terminal and clone the repository:
      ```sh
      git clone https://github.com/ckellywilson/aks-weather.git
      cd aks-weather
      ```

5. **Open the Project in a Dev Container**:
    - Open the cloned repository in Visual Studio Code.
    - Press `F1` and select `Remote-Containers: Open Folder in Container...`.
    - Select the project folder.

## Instructions for WSL

1. **Install WSL**:
    - Follow the instructions to install WSL from [Microsoft's official documentation](https://docs.microsoft.com/en-us/windows/wsl/install).

2. **Install Docker Desktop**:
    - Download and install Docker Desktop from [Docker's official website](https://www.docker.com/products/docker-desktop).
    - Ensure Docker is running and WSL integration is enabled.

3. **Install Visual Studio Code**:
    - Download and install Visual Studio Code from [Visual Studio Code's official website](https://code.visualstudio.com/).

4. **Install Remote - WSL and Remote - Containers Extensions**:
    - Open Visual Studio Code.
    - Go to the Extensions view by clicking on the Extensions icon in the Activity Bar on the side of the window.
    - Search for `Remote - WSL` and install it.
    - Search for `Remote - Containers` and install it.

5. **Clone the Repository**:
    - Open a WSL terminal and clone the repository:
      ```sh
      git clone https://github.com/ckellywilson/aks-weather.git
      cd aks-weather
      ```

6. **Open the Project in a Dev Container**:
    - Open the cloned repository in Visual Studio Code.
    - Press `F1` and select `Remote-Containers: Open Folder in Container...`.
    - Select the project folder.

Follow these steps to set up the project with dev containers on both Windows and WSL.

## Containerizing the Application with VS Code Docker Extension

### Prerequisites

- Docker Desktop
- Visual Studio Code
- Docker extension for Visual Studio Code

### Instructions

1. **Install Docker Extension**:
    - Open Visual Studio Code.
    - Go to the Extensions view by clicking on the Extensions icon in the Activity Bar on the side of the window.
    - Search for `Docker` and install it.

2. **Add Docker Files to Workspace**:
    - Open your project in Visual Studio Code.
    - Press `F1` to open the command palette.
    - Type `Docker: Add Docker Files to Workspace` and select it.
    - Follow the prompts to select the application platform (e.g., Node.js, Python, etc.) and port number.

3. **Review and Customize Docker Files**:
    - Visual Studio Code will generate `Dockerfile` and `docker-compose.yml` files in your project.
    - Review the generated files and make any necessary customizations to fit your application's requirements.

4. **Build and Run the Docker Containers**:
    - Open a terminal in Visual Studio Code.
    - Build the Docker images using Docker Compose:
      ```sh
      docker-compose build
      ```
    - Run the Docker containers:
      ```sh
      docker-compose up
      ```

5. **Verify the Application**:
    - Open a web browser and navigate to `http://localhost:<port>` to verify that your application is running inside the Docker container.

By following these steps, you can containerize your application using the VS Code Docker extension.

## Deploying AKS Infrastructure and Push image to ACR

### Prerequisites

- Azure CLI installed. Azure CLI is included as part of this dev container.

### Instructions

1. **Login to Azure**:
    - Open a terminal.
    - Login to your Azure account using the Azure CLI:
      ```sh
      az login
      ```
    - Follow the instructions to complete the authentication process.

2. **Execute the Deployment Script**:
    - Ensure you are in the root directory of the cloned repository.
    - Execute change mod to execute script
      ```sh
      chmod +x deploy.sh
      ```
    - Run the deployment script to set up the AKS infrastructure:
      ```sh
      ./deploy.sh
      ```

This will set up the necessary Azure Kubernetes Service (AKS) infrastructure for your project and push image to ACR

## Deploying Kubernetes Workload

### Prerequisites

- Kubernetes CLI (`kubectl`) installed. `kubectl` is included as part of this dev container.

### Instructions

1. **Configure kubectl**:
    - Ensure your `kubectl` is configured to use the AKS cluster:
      ```sh
      az aks get-credentials --resource-group <ResourceGroupName> --name <ClusterName>
      ```

2. **Deploy the Workload**:
    - Navigate to the `k8s` directory:
      ```sh
      cd k8s
      ```
    - Apply the Kubernetes manifests to deploy the workload:
      ```sh
      kubectl apply -f .
      ```

3. **Verify the Deployment**:
    - Check the status of the pods to ensure they are running:
      ```sh
      kubectl get pods
      ```
    - Verify the services to ensure they are exposed correctly:
      ```sh
      kubectl get services
      ```

By following these steps, you can deploy your Kubernetes workload using the manifests in the `k8s` folder.
