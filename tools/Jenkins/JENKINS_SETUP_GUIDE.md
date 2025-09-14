# 🚀 Jenkins CI/CD Pipeline Setup Guide

Complete setup guide for running the Chattingo application Jenkins pipeline with environment-based deployments.

## 📋 Prerequisites

### System Requirements
- **Docker & Docker Compose**: Latest versions installed
- **Minimum Hardware**: 4GB RAM, 2 CPU cores, 10GB free disk space
- **Operating System**: Linux, macOS, or Windows with WSL2
- **Ports Available**: 8080 (Jenkins UI), 50000 (Jenkins agents)

### Accounts & Access
- **Docker Hub Account**: For pushing/pulling images
- **GitHub Access**: To your Chattingo repository
- **Domain Access**: If using custom domains (optional)

## 🛠️ Step 1: Jenkins Server Setup

### 1.1 Create Environment File
First, create the Jenkins environment file:

```bash
cd /home/ubuntu/Desktop/chattingo/tools/Jenkins
```

Create `.env.jenkins` file:
```bash
# Jenkins Configuration
JENKINS_OPTS="--sessionTimeout=1440 --sessionEviction=1800"
JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Xmx1024m"

# Build Configuration  
DOCKER_HOST=unix:///var/run/docker.sock
COMPOSE_PROJECT_NAME=jenkins_chattingo
```

### 1.2 Start Jenkins Server
```bash
# Start Jenkins with Docker Compose
docker-compose -f docker-compose-jenkins.yml up -d

# Check if Jenkins is running
docker-compose -f docker-compose-jenkins.yml ps

# View Jenkins logs
docker-compose -f docker-compose-jenkins.yml logs -f jenkins
```

### 1.3 Initial Jenkins Access
1. **Wait for startup** (2-3 minutes)
2. **Access Jenkins**: http://localhost:8080
3. **Get initial admin password**:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
4. **Complete Setup Wizard**:
   - Install suggested plugins
   - Create admin user
   - Set Jenkins URL (e.g., `http://localhost:8080`)

## 🔐 Step 2: Jenkins Credentials Configuration

### 2.1 Docker Hub Credentials
1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **System** → **Global credentials** → **Add Credentials**
3. **Kind**: Username with password
4. **Scope**: Global
5. **Username**: Your Docker Hub username (`adityagaikwad888`)
6. **Password**: Your Docker Hub access token
7. **ID**: `dockerhub-credentials`
8. **Description**: Docker Hub Access Token

### 2.2 Environment Files as Secret Files

#### 2.2.1 Development Environment
1. **Add Credentials** → **Secret file**
2. **File**: Upload your `.env.dev` file (from `env-templates/`)
3. **ID**: `env-file-dev`
4. **Description**: Development Environment Variables

#### 2.2.2 Staging Environment  
1. **Add Credentials** → **Secret file**
2. **File**: Upload your `.env.staging` file
3. **ID**: `env-file-staging` 
4. **Description**: Staging Environment Variables

#### 2.2.3 Production Environment
1. **Add Credentials** → **Secret file**
2. **File**: Upload your `.env.prod` file
3. **ID**: `env-file-prod`
4. **Description**: Production Environment Variables

## 📦 Step 3: Required Jenkins Plugins

### 3.1 Install Essential Plugins
Go to **Manage Jenkins** → **Manage Plugins** → **Available** and install:

```
✅ Pipeline: Stage View
✅ Docker Pipeline  
✅ Docker Commons
✅ Blue Ocean (optional, for better UI)
✅ HTML Publisher (for coverage reports)
✅ Build Timeout
✅ Timestamper
✅ Workspace Cleanup
✅ Git
✅ GitHub
✅ Credentials Binding
✅ Pipeline: GitHub Groovy Libraries
```

### 3.2 Configure Docker Access
1. **Manage Jenkins** → **Configure System**
2. **Docker** section:
   - **Docker URL**: `unix:///var/run/docker.sock`
   - **Test Connection** (should show ✅)

## 🔄 Step 4: Pipeline Job Creation

### 4.1 Create New Pipeline Job
1. **New Item** → Enter name: `chattingo-pipeline`
2. **Select**: Pipeline
3. **Click OK**

### 4.2 Configure Pipeline Job

#### General Settings
- ✅ **This project is parameterized**
- ✅ **Do not allow concurrent builds**
- **Description**: "Chattingo CI/CD Pipeline with Environment Support"

#### Build Triggers (Optional)
- ✅ **GitHub hook trigger for GITScm polling** (if using GitHub webhooks)
- ✅ **Poll SCM**: `H/5 * * * *` (every 5 minutes)

#### Pipeline Configuration
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/adityagaikwad888/chattingo.git`
- **Branch Specifier**: `*/main`
- **Script Path**: `tools/Jenkins/Jenkinsfile`

### 4.3 Save Configuration

## 🧪 Step 5: Test Pipeline Execution

### 5.1 Manual Build Test
1. **Go to your pipeline job**
2. **Click "Build with Parameters"**
3. **Select parameters**:
   - **Environment**: `dev`
   - **Skip Tests**: `false`
   - **Deploy After Build**: `false`
4. **Click "Build"**

### 5.2 Monitor Build Progress
1. **Click on build number** (#1, #2, etc.)
2. **View "Console Output"** for detailed logs
3. **Check "Pipeline Steps"** for stage-by-stage progress

## 🔍 Step 6: Verification & Troubleshooting

### 6.1 Success Indicators
✅ **Environment file loaded successfully**
✅ **Backend tests pass** (if not skipped)
✅ **Frontend tests pass** (if not skipped)
✅ **Docker images built and pushed**
✅ **No red stages in pipeline**

### 6.2 Common Issues & Solutions

#### Issue: Environment file not found
```
❌ Error: "Environment file not found!"
```
**Solution**: 
- Verify secret file credentials are uploaded
- Check credential IDs match exactly: `env-file-dev`, `env-file-staging`, `env-file-prod`

#### Issue: Docker permission denied
```
❌ Error: "permission denied while trying to connect to Docker daemon"
```
**Solution**:
```bash
# Add jenkins user to docker group
docker exec -u root jenkins usermod -aG docker jenkins
docker-compose -f docker-compose-jenkins.yml restart
```

#### Issue: Maven/Node not found
```
❌ Error: "mvn: command not found"
```
**Solution**: This should not happen as we use Docker agents. Check if Docker is running properly.

#### Issue: Docker Hub login fails
```
❌ Error: "unauthorized: authentication required"
```
**Solution**:
- Verify Docker Hub credentials in Jenkins
- Use access token instead of password
- Check username is correct (`adityagaikwad888`)

## 📊 Step 7: Build Results & Artifacts

### 7.1 What to Expect After Successful Build

#### Build Artifacts
- **Backend JAR**: `backend/target/*.jar`
- **Frontend Build**: `frontend/build/`
- **Test Reports**: JUnit XML and HTML coverage
- **Deployment Package**: `deployment-{env}-{build}.tar.gz`

#### Docker Images Pushed
```
adityagaikwad888/chattingo-backend:dev-{BUILD_NUMBER}
adityagaikwad888/chattingo-backend:dev-latest
adityagaikwad888/chattingo-frontend:dev-{BUILD_NUMBER}
adityagaikwad888/chattingo-frontend:dev-latest
```

### 7.2 Accessing Build Results
1. **Artifacts**: Available in build page
2. **Test Results**: JUnit trend graphs
3. **Coverage Reports**: HTML Publisher plugin results
4. **Console Logs**: Full build execution details

## 🚀 Step 8: Advanced Configuration

### 8.1 GitHub Webhook Integration
1. **GitHub Repository** → **Settings** → **Webhooks**
2. **Add webhook**:
   - **Payload URL**: `http://your-jenkins-url:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Push events

### 8.2 Notification Setup (Optional)
Configure email or Slack notifications:
1. **Manage Jenkins** → **Configure System**
2. **Email Notification** or **Slack** plugin configuration
3. Add notifications to pipeline `post` sections

### 8.3 Resource Limits (Production)
For production Jenkins, adjust in `docker-compose-jenkins.yml`:
```yaml
deploy:
  resources:
    limits:
      memory: 4G        # Increase for large builds
      cpus: '2.0'       # More CPU for parallel builds
```

## 📝 Step 9: Daily Operations

### 9.1 Regular Builds
- **Development**: Trigger on every commit to `develop` branch
- **Staging**: Manual trigger or scheduled (daily)
- **Production**: Manual trigger only, with approval process

### 9.2 Monitoring & Maintenance
```bash
# Check Jenkins health
docker-compose -f docker-compose-jenkins.yml ps

# View recent logs
docker-compose -f docker-compose-jenkins.yml logs --tail=100 jenkins

# Backup Jenkins data
docker cp jenkins:/var/jenkins_home ./jenkins_backup_$(date +%Y%m%d)

# Clean old Docker images
docker system prune -f
```

### 9.3 Environment Updates
When environment variables change:
1. Update the `.env.{environment}` file
2. Re-upload as secret file in Jenkins credentials  
3. Trigger new build to use updated configuration

## ✅ Final Checklist

Before going live, ensure:

- [ ] Jenkins server is running and accessible
- [ ] All required plugins are installed
- [ ] Docker Hub credentials are configured
- [ ] All three environment files are uploaded as secret files
- [ ] Pipeline job is created and configured
- [ ] Test build has completed successfully
- [ ] Docker images are appearing in Docker Hub
- [ ] Build artifacts are being archived
- [ ] Test results are being published

## 🆘 Need Help?

### Logs to Check
1. **Jenkins Server Logs**: `docker-compose logs jenkins`
2. **Pipeline Console**: In Jenkins UI → Build → Console Output
3. **Docker Daemon**: `docker system events`

### Key File Locations
- **Jenkins Home**: `/var/jenkins_home` (inside container)
- **Environment Files**: Jenkins Credentials → Secret Files
- **Pipeline Definition**: `tools/Jenkins/Jenkinsfile`
- **Docker Compose**: `tools/Jenkins/docker-compose-jenkins.yml`

---

🎉 **You're ready to run production CI/CD for Chattingo!** 

The pipeline supports environment-specific builds, comprehensive testing, Docker image management, and deployment preparation. All secrets are securely managed through Jenkins credentials system.
