<h1 align="center">GZCTF-QUICK-DEPLOY</h4>

<h4 align="center">Bash script for GZCTF platform deployment</h4>

<p align="center">
    <img src="https://img.shields.io/badge/platform-linux-00CC66">
    <img src="https://img.shields.io/badge/Ubuntu-20.xx%20%7C%2022.xx-0099FF">
    <img src="https://img.shields.io/badge/Docker-Required-E4A5B3">
    <img src="https://img.shields.io/badge/Category-automation-9933FF">
</p>

An automated deployment script for GZCTF platform on Ubuntu systems. This script streamlines the installation process of the GZCTF platform.



## Features

- Automated dependency installation (Docker, Docker Compose, PostgreSQL client)

- Creates server config in unified format

  

## Prerequisites

- Ubuntu 20.xx/22.xx LTS

- Root privileges

- Stable internet connection

- Minimum 2GB RAM

- 10GB available disk space

  

## Usage

```bash
bash ./deploy.sh
```



## Configuration

- ### Default Ports

  - Web Interface: 80 (mapped to container port 8080)
  - PostgreSQL: 5432 (internal container access)



## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.



## Author

- [Cyr1s](https://cyr1s-dev.github.io/about/)



## Acknowledgments

Special thanks to the [GZCTF](https://github.com/GZTimeWalker/GZCTF) team for their excellent platform.
