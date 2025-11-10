#!/bin/bash
# Quick check script - run before disconnecting

echo "🔍 Checking what's running before disconnect..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Memory Usage:"
free -h | grep "Mem:" | awk '{print "Used: "$3" / "$2" (Available: "$7")"}'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐍 Python processes running:"
PYTHON_COUNT=$(ps aux | grep python | grep -v grep | wc -l)
if [ $PYTHON_COUNT -eq 0 ]; then
    echo "✅ None (safe to disconnect)"
else
    echo "⚠️  $PYTHON_COUNT Python process(es) running:"
    ps aux | grep python | grep -v grep | awk '{print "  - PID "$2": "$11" "$12" "$13}'
    echo ""
    echo "💡 These will STOP when you disconnect!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Open ports (services):"
PORTS=$(ss -tuln | grep LISTEN | grep -v "127.0.0.1" | grep -v "::1" | wc -l)
if [ $PORTS -eq 0 ]; then
    echo "✅ No public services running"
else
    echo "⚠️  $PORTS port(s) listening:"
    ss -tuln | grep LISTEN | grep -v "127.0.0.1" | grep -v "::1"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Summary:"
echo "  • SSH uses ~22 MB RAM (0.006% of server)"
echo "  • Cursor uses ~700 MB RAM (0.18% of server)"
echo "  • Cost impact: Minimal (~$0.001/hour)"
echo ""
echo "💡 To disconnect:"
echo "  → Type: exit"
echo "  → Or press: Ctrl+D"
echo "  → Or close Cursor IDE"
echo ""


