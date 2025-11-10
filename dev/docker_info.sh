#!/bin/bash
# Docker Container Information Script

echo "═══════════════════════════════════════════════════"
echo "  🐳 DOCKER CONTAINER INFORMATION"
echo "═══════════════════════════════════════════════════"
echo ""

echo "📦 Container Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Container ID: $(hostname)"
echo "Virtualization: $(systemd-detect-virt 2>/dev/null || echo 'unknown')"
echo "Hostname: $(cat /etc/hostname)"
echo ""

echo "💾 Filesystem:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
df -h / | awk 'NR==1 || NR==2 {print}'
echo "Type: $(df -T / | awk 'NR==2 {print $2}')"
echo ""

echo "🐧 Operating System:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat /etc/os-release | grep "PRETTY_NAME" | cut -d'\"' -f2
echo "Kernel: $(uname -r)"
echo ""

echo "🚀 Running Processes:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PID 1 (Init Process): $(ps -p 1 -o comm=)"
echo "Total Processes: $(ps aux | wc -l)"
echo ""

echo "📊 Resources:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
free -h | grep "Mem:" | awk '{print "Memory: "$3" used / "$2" total"}'
echo "CPU Cores: $(nproc)"
echo ""

echo "🌐 Network:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo ""

echo "═══════════════════════════════════════════════════"
echo "  💡 WHAT THIS MEANS"
echo "═══════════════════════════════════════════════════"
echo ""
echo "✅ You ARE in a Docker container"
echo "✅ Railway manages this container"
echo "✅ Container ID: $(hostname)"
echo ""
echo "⚠️  IMPORTANT:"
echo "   • Files created here are TEMPORARY"
echo "   • Container may be recreated anytime"
echo "   • For permanent files → Use Git repository"
echo "   • Manual changes → Will be LOST on restart"
echo ""
echo "📚 Docker Benefits:"
echo "   • Isolated environment (secure)"
echo "   • Consistent setup (predictable)"
echo "   • Easy deployment (Railway manages it)"
echo "   • Resource controlled (limited RAM/CPU)"
echo ""


