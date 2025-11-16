# SteemAuto - Steem Blockchain Automation Platform

![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)
![Node](https://img.shields.io/badge/node-%3E%3D14.0.0-brightgreen.svg)
![PHP](https://img.shields.io/badge/php-%3E%3D7.4-blue.svg)

SteemAuto is a comprehensive automation platform for the Steem blockchain, providing powerful tools for curation trails, fanbase management, scheduled posts, and automated voting.

## 🚀 Features

- **Curation Trails**: Follow your favorite curators and automatically vote on content they upvote
- **Fanbase Management**: Automatically support your followers with configurable voting rules
- **Scheduled Posts**: Schedule your Steem posts for future publication
- **Comment Auto-Upvote**: Automatically upvote comments from specific users
- **Claim Rewards**: Automate reward claiming from the blockchain
- **Voting Power Management**: Intelligent mana management to optimize your voting strategy

## 📋 Quick Start

### Option 1: Automated Installation (Recommended)

```bash
git clone https://github.com/yourusername/steemauto.git
cd steemauto
chmod +x scripts/install.sh
./scripts/install.sh
```

### Option 2: Manual Setup

See [QUICK_START.md](QUICK_START.md) for a condensed guide or [SETUP_GUIDE.md](SETUP_GUIDE.md) for comprehensive instructions.

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - Get started in minutes
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup instructions
- **[MODERNIZATION_ROADMAP.md](MODERNIZATION_ROADMAP.md)** - Future development plan

## 🛠️ Tech Stack

### Current Stack
- **Frontend**: PHP 7.4+, HTML5, Bootstrap 3, JavaScript/jQuery
- **Backend**: Node.js 14+, Express
- **Database**: MySQL 5.7+
- **Process Manager**: PM2
- **Web Server**: Apache2 or Nginx

### Roadmap Stack
- **Frontend**: React 18, Next.js 14, TypeScript, Tailwind CSS
- **Backend**: Node.js 20, Express, TypeScript
- **Database**: MySQL 8.0
- **Caching**: Redis 7.x
- **Monitoring**: Prometheus + Grafana

See [MODERNIZATION_ROADMAP.md](MODERNIZATION_ROADMAP.md) for details.

## 📦 Installation

### Prerequisites

- Ubuntu 20.04+ (or compatible Linux)
- 2GB+ RAM
- 20GB+ disk space
- Steem account with posting authority

### System Requirements

```bash
Node.js >= 14.0.0
PHP >= 7.4
MySQL >= 5.7
Apache2 or Nginx
PM2
```

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/steemauto.git
   cd steemauto
   ```

2. **Run installation script**
   ```bash
   chmod +x scripts/install.sh
   ./scripts/install.sh
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   nano .env
   # Update DB_PASSWORD and STEEM_WIF_KEY
   ```

4. **Start services**
   ```bash
   pm2 start ecosystem.config.js
   pm2 save
   pm2 startup systemd
   ```

5. **Access application**
   - Open browser to `http://localhost` or your domain

## 🔧 Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Database
DB_HOST=127.0.0.1
DB_USER=steemauto_user
DB_PASSWORD=your_password
DB_NAME=steemauto

# Steem Blockchain
STEEM_WIF_KEY=your_posting_private_key
STEEM_RPC=wss://api.steemit.com

# Application
NODE_ENV=production
APP_URL=https://yourdomain.com
```

## 🚦 Usage

### Starting Services

```bash
# Start all services
pm2 start ecosystem.config.js

# View status
pm2 status

# View logs
pm2 logs

# Monitor resources
pm2 monit
```

### Managing Services

```bash
# Restart all
pm2 restart all

# Stop all
pm2 stop all

# Restart specific service
pm2 restart steemauto-trail
```

## 🔒 Security

⚠️ **Important**: This application currently has critical security vulnerabilities that must be addressed before production use.

### Known Issues
- SQL injection vulnerabilities
- XSS vulnerabilities
- Insecure WIF key transmission
- Missing CSRF protection
- Hardcoded credentials

### Immediate Actions Required

1. Review the security section in [SETUP_GUIDE.md](SETUP_GUIDE.md)
2. Follow Phase 1 of [MODERNIZATION_ROADMAP.md](MODERNIZATION_ROADMAP.md)
3. Never use in production without fixing security issues

### Security Checklist

- [ ] Fix SQL injection (use prepared statements)
- [ ] Implement XSS protection (escape all output)
- [ ] Secure WIF key transmission
- [ ] Add CSRF tokens to forms
- [ ] Move credentials to environment variables
- [ ] Enable HTTPS
- [ ] Setup firewall
- [ ] Enable fail2ban
- [ ] Regular security updates

## 📊 Monitoring

### Health Check

```bash
bash scripts/health-check.sh
```

### View Logs

```bash
# PM2 logs
pm2 logs

# Apache logs
sudo tail -f /var/log/apache2/steemauto-error.log

# MySQL logs
sudo tail -f /var/log/mysql/error.log
```

## 💾 Backup

### Manual Backup

```bash
bash scripts/backup.sh
```

### Automated Backups

Add to crontab for daily backups at 2 AM:

```bash
crontab -e
# Add this line:
0 2 * * * /home/user/steemauto/scripts/backup.sh
```

## 🧪 Testing

### Run Tests (Coming Soon)

```bash
# Node.js tests
npm test

# PHP tests
vendor/bin/phpunit

# Linting
npm run lint
```

## 🚀 Deployment

### Production Deployment

```bash
# Pull latest changes
git pull origin main

# Run deployment script
bash scripts/deploy.sh
```

### SSL Certificate

```bash
sudo certbot --apache -d yourdomain.com -d www.yourdomain.com
```

## 📈 Roadmap

See [MODERNIZATION_ROADMAP.md](MODERNIZATION_ROADMAP.md) for detailed development plan.

### Short Term (Months 1-2)
- ✅ Critical security fixes
- ✅ Code quality improvements
- ✅ Testing infrastructure
- ⬜ Database schema improvements

### Medium Term (Months 3-4)
- ⬜ RESTful API with authentication
- ⬜ Modern React frontend
- ⬜ Redis caching
- ⬜ CI/CD pipeline

### Long Term (Months 5-6)
- ⬜ Real-time WebSocket updates
- ⬜ Mobile application
- ⬜ Multi-language support
- ⬜ Advanced analytics

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone repo
git clone https://github.com/yourusername/steemauto.git
cd steemauto

# Install dependencies
npm install

# Setup development environment
cp .env.example .env
# Edit .env with your credentials

# Start services in development mode
NODE_ENV=development pm2 start ecosystem.config.js
```

## 📝 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Original Author** - SteemAuto Team
- **Contributors** - See contributors list

## 🙏 Acknowledgments

- Steem blockchain community
- All contributors and users
- Open source libraries used in this project

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/steemauto/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/steemauto/discussions)
- **Website**: https://steemauto.com

## 📖 Additional Resources

- [Steem Developer Documentation](https://developers.steem.io/)
- [SteemConnect Documentation](https://steemconnect.com/)
- [PM2 Documentation](https://pm2.keymetrics.io/)

## ⚙️ System Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       ▼
┌─────────────┐      ┌──────────────┐
│  Apache2    │─────▶│  PHP Files   │
│ (Web Server)│      │  (Frontend)  │
└─────────────┘      └──────┬───────┘
                            │
                            ▼
                     ┌──────────────┐
                     │    MySQL     │
                     │  (Database)  │
                     └──────┬───────┘
                            │
                            ▼
┌─────────────┐      ┌──────────────┐      ┌──────────────┐
│ PM2 Process │─────▶│   Node.js    │─────▶│    Steem     │
│   Manager   │      │  (Services)  │      │  Blockchain  │
└─────────────┘      └──────────────┘      └──────────────┘
```

## 🔄 Service Architecture

```
PM2 Services:
├── steemauto-upvote      (HTTP server on port 7412)
├── steemauto-trail       (Curation trail processor)
├── steemauto-fan         (Fanbase processor)
├── steemauto-commentup   (Comment upvote service)
├── steemauto-schedule    (Scheduled posts)
├── steemauto-delay       (Delayed votes)
├── steemauto-claimreward (Reward claiming)
└── steemauto-votepower   (Voting power updates)
```

## 📊 Database Schema

```
Tables (11):
├── users          (User accounts and settings)
├── trailers       (Curation trail creators)
├── followers      (Trail followers)
├── fans           (Fanbase creators)
├── fanbase        (Fan relationships)
├── posts          (Scheduled posts)
├── commentupvote  (Comment upvote rules)
├── upvotelater    (Delayed upvotes queue)
├── upvotedcomments(Processed comments)
├── donations      (Donation tracking)
└── blacklist      (Blacklisted users)
```

## 🐛 Known Issues

See [GitHub Issues](https://github.com/yourusername/steemauto/issues) for current bugs and feature requests.

## 🔮 Future Enhancements

- TypeScript migration
- GraphQL API
- Progressive Web App (PWA)
- Docker containerization
- Kubernetes deployment
- Advanced analytics dashboard
- AI-powered content recommendations

---

**Version**: 1.0.0
**Last Updated**: 2025-01-16

Made with ❤️ for the Steem community
