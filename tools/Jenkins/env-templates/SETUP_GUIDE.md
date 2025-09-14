# 🔐 Jenkins Secret Files Setup Guide

## 📋 Overview

Instead of storing `.env.*` files in your Git repository, you'll store them as **Secret Files** in Jenkins. This ensures sensitive information like passwords, API keys, and secrets are never exposed in your codebase.

## 🚀 Setup Steps

### Step 1: Prepare Environment Files

1. **Review the template files** in this directory:
   - `.env.dev` - Development environment
   - `.env.staging` - Staging environment  
   - `.env.prod` - Production environment

2. **Customize for your needs**:
   - Replace `yourdomain.com` with your actual domain
   - Update `CHANGE_ME_*` values with secure passwords
   - Configure cloud credentials if needed
   - Set proper database passwords

### Step 2: Upload to Jenkins as Secret Files

#### 2.1 Navigate to Jenkins Credentials
1. Go to Jenkins Dashboard
2. Click `Manage Jenkins`
3. Click `Manage Credentials`
4. Click `System`
5. Click `Global credentials (unrestricted)`

#### 2.2 Add Development Environment File
1. Click `Add Credentials`
2. **Kind**: Select `Secret file`
3. **File**: Upload your customized `.env.dev` file
4. **ID**: `env-file-dev` (exactly as shown)
5. **Description**: `Development environment configuration file`
6. Click `OK`

#### 2.3 Add Staging Environment File
1. Click `Add Credentials`
2. **Kind**: Select `Secret file`
3. **File**: Upload your customized `.env.staging` file
4. **ID**: `env-file-staging` (exactly as shown)
5. **Description**: `Staging environment configuration file`
6. Click `OK`

#### 2.4 Add Production Environment File
1. Click `Add Credentials`
2. **Kind**: Select `Secret file`
3. **File**: Upload your customized `.env.prod` file
4. **ID**: `env-file-prod` (exactly as shown)
5. **Description**: `Production environment configuration file`
6. Click `OK`

### Step 3: Verify Credentials

Your Jenkins credentials should now show:
- `dockerhub-credentials` (Username with password)
- `env-file-dev` (Secret file)
- `env-file-staging` (Secret file)
- `env-file-prod` (Secret file)

## 🔧 Required Credential IDs

The Jenkinsfile expects these exact credential IDs:

| Credential ID | Type | Description |
|---------------|------|-------------|
| `dockerhub-credentials` | Username with password | Docker Hub login |
| `env-file-dev` | Secret file | Development environment |
| `env-file-staging` | Secret file | Staging environment |
| `env-file-prod` | Secret file | Production environment |

## 🎯 How the Pipeline Uses These Files

### Pipeline Flow:
1. **Environment Selection**: User selects `dev`, `staging`, or `prod`
2. **File Loading**: Pipeline loads corresponding `.env.*` file from Jenkins
3. **Validation**: Checks for required variables
4. **Build Process**: Uses environment variables for builds
5. **Docker Images**: Tagged with environment-specific labels

### Environment-Specific Features:
```bash
# Development
- Debug logging enabled
- Relaxed security settings  
- Local domain names
- Source maps enabled

# Staging  
- Production-like settings
- SSL/TLS enabled
- Real domain names
- Reduced resource usage

# Production
- Maximum security
- Strong passwords required
- Cloud integrations
- Full resource allocation
```

## 🔒 Security Benefits

✅ **Never in Git**: Environment files never stored in repository  
✅ **Encrypted Storage**: Jenkins encrypts secret files at rest  
✅ **Access Control**: Role-based access to credentials  
✅ **Audit Trail**: Jenkins logs credential access  
✅ **Rotation Ready**: Easy to update credentials without code changes  

## 📊 Pipeline Parameters

When running the pipeline, you can:

- **ENVIRONMENT**: Choose `dev`, `staging`, or `prod`
- **SKIP_TESTS**: Skip tests for faster builds
- **DEPLOY_AFTER_BUILD**: Prepare K8s deployment artifacts

## 🚨 Important Notes

### For Production:
- **Change ALL** `CHANGE_ME_*` values
- Use **strong passwords** (minimum 12 characters)
- Configure **real domain names**  
- Set up **proper SSL certificates**
- Enable **monitoring and backups**

### For Development:
- Weaker passwords are acceptable
- Local domain names (chattingo.local)
- Debug logging enabled
- Source maps for easier debugging

### Security Checklist:
- [ ] All `CHANGE_ME_*` values replaced
- [ ] JWT secrets are 256-bit (32+ characters)  
- [ ] Database passwords are strong
- [ ] Production domains configured
- [ ] SSL/TLS settings verified
- [ ] Monitoring credentials set

## 🔄 Updating Environment Files

To update an environment file:

1. **Edit the local file** with new values
2. **Go to Jenkins** → `Manage Credentials`  
3. **Find the credential** (e.g., `env-file-prod`)
4. **Click Update**
5. **Upload the new file**
6. **Save changes**

The next pipeline run will use the updated configuration automatically!

## 🆘 Troubleshooting

### File Not Found Error:
```
❌ Environment file not found: .env.prod
```
**Solution**: Verify credential ID matches exactly (`env-file-prod`)

### Missing Variables Error:
```
❌ Missing required variables in environment file: JWT_SECRET
```
**Solution**: Ensure your environment file contains all required variables

### Permission Error:
```
❌ Access denied to credential
```
**Solution**: Check user permissions for credentials access

## 🎉 Benefits of This Approach

1. **🔐 Security First**: Secrets never in Git
2. **🌍 Multi-Environment**: Easy environment management  
3. **🚀 CI/CD Ready**: Seamless pipeline integration
4. **🔄 Easy Updates**: Change configs without code
5. **📊 Environment Parity**: Consistent configurations
6. **🛡️ Access Control**: Role-based credential management

Your ChatTingo application is now ready for secure, environment-specific deployments! 🚀
