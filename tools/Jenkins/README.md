# 🚀 Chattingo Jenkins CI/CD

Clean and organized Jenkins setup for the Chattingo application with environment-based deployments.

## 📁 Structure

```
tools/Jenkins/
├── Jenkinsfile                          # Main CI/CD pipeline
├── docker-compose-jenkins.yml           # Jenkins server setup
├── .gitignore                           # Git ignore rules
├── ENHANCED_JENKINSFILE_README.md       # Detailed pipeline documentation
└── env-templates/                       # Environment configurations
    ├── .env.dev                        # Development environment
    ├── .env.prod                       # Production environment  
    ├── .env.staging                    # Staging environment
    ├── SETUP_GUIDE.md                  # Step-by-step setup guide
    └── COMPLETE_VARIABLES_REFERENCE.md  # All 200+ variables documented
```

## 🎯 Quick Start

### 1. **Start Jenkins Server**
```bash
cd tools/Jenkins
docker-compose -f docker-compose-jenkins.yml up -d
```

### 2. **Configure Environment Files**
- Customize the files in `env-templates/` for your environments
- Upload them to Jenkins as Secret Files:
  - `env-file-dev` ← `.env.dev`
  - `env-file-staging` ← `.env.staging`  
  - `env-file-prod` ← `.env.prod`

### 3. **Set up Pipeline**
- Create a new Pipeline job in Jenkins
- Point it to your Git repository
- Use the `Jenkinsfile` from this directory

### 4. **Run Builds**
- Select environment: `dev`, `staging`, or `prod`
- Choose options: skip tests, deploy after build
- Execute and monitor the pipeline

## ✨ Key Features

- 🔐 **Secure**: All secrets managed via Jenkins credentials
- 🌍 **Multi-Environment**: Separate configs for dev/staging/prod
- 🏗️ **Parallel Builds**: Frontend and backend build simultaneously
- 🐳 **Environment Tags**: Docker images tagged per environment
- 📊 **Complete Variables**: 200+ environment variables supported
- 🚀 **Production Ready**: Security best practices built-in

## 📖 Documentation

- **Pipeline Details**: See `ENHANCED_JENKINSFILE_README.md`
- **Environment Setup**: See `env-templates/SETUP_GUIDE.md`
- **All Variables**: See `env-templates/COMPLETE_VARIABLES_REFERENCE.md`

## 🔄 Workflow

1. **Developer pushes code** → Triggers Jenkins
2. **Environment selected** → Loads appropriate `.env.*` file
3. **Parallel builds** → Frontend (Node.js) + Backend (Java)
4. **Docker images built** → Tagged with environment + build number
5. **Images pushed** → To Docker Hub with multiple tags
6. **Optional deployment** → K8s manifests prepared

Ready for production deployment! 🎉
