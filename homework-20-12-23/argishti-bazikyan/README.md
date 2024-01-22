# Devops Scripts

This project will contain my personal scripts

## Getting Started

These instructions will guide you on setting up and running the project on your local machine.

### Prerequisites

Before you begin, ensure you have the following installed:

- [AWS CLI](https://aws.amazon.com/cli/)
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/Bazikyan/devops.git
    ```

2. Change into the project directory:

    ```bash
    cd devops
    ```

3. Copy the `.env.example` file to `.env`:

    ```bash
    cp .env.example .env
    ```

4. Open the `.env` file in a text editor and fill in your AWS credentials:

    ```env
    AWS_ACCESS_KEY_ID=your_access_key_id
    AWS_SECRET_ACCESS_KEY=your_secret_access_key
    ```

5. Save the `.env` file.

### Usage

Execute the script to launch an EC2 instance:

```bash
./launch_ec2.sh
