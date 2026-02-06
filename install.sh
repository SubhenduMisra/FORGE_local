#!/bin/bash
set -e

SPARK_IP="192.168.68.135"
SPARK_USER="misras"

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' P='\033[0;35m' N='\033[0m'

clear
echo -e "${P}"
cat << 'BANNER'
    ███████╗ ██████╗ ██████╗  ██████╗ ███████╗
    ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝
    █████╗  ██║   ██║██████╔╝██║  ███╗█████╗  
    ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  
    ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
    ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
    Multi-GPU AI Development Studio v4
BANNER
echo -e "${N}"

echo -e "${B}[1/6]${N} Installing Homebrew packages..."
brew install node python@3.11 jq ollama 2>/dev/null || true
brew services start ollama 2>/dev/null || true

echo -e "${B}[2/6]${N} Pulling Ollama models..."
(ollama pull qwen2.5-coder:14b; ollama pull nomic-embed-text) &

echo -e "${B}[3/6]${N} Installing Claude Code Router..."
npm install -g @musistudio/claude-code-router 2>/dev/null || true

echo -e "${B}[4/6]${N} Creating config..."
mkdir -p ~/forge ~/.forge ~/.claude-code-router

cat > ~/.claude-code-router/config.json << CONF
{"port":3456,"providers":[{"id":"macbook","type":"ollama","baseUrl":"http://localhost:11434","priority":0},{"id":"dgx-spark","type":"openai-compatible","baseUrl":"http://${SPARK_IP}:8000/v1","apiKey":"local","priority":1}],"routing":{"default":"macbook","code-generation":"dgx-spark","architect":"anthropic"}}
CONF

echo -e "${B}[5/6]${N} Creating forge CLI..."
cat > ~/forge/forge << 'CLI'
#!/bin/bash
case "$1" in
  status) echo "💻 Mac: $(pgrep ollama >/dev/null && echo '✅' || echo '❌') | ⚡ Spark: $(ssh -o ConnectTimeout=2 misras@192.168.68.135 'echo ✅' 2>/dev/null || echo '❌')" ;;
  code) ccr code ;;
  spark) shift; case "$1" in ssh) ssh misras@192.168.68.135 ;; start) ssh misras@192.168.68.135 "cd /opt/forge && docker compose up -d" ;; stop) ssh misras@192.168.68.135 "cd /opt/forge && docker compose down" ;; esac ;;
  github) shift; cd ~/forge-github 2>/dev/null && git "$@" ;;
  *) echo "Usage: forge [status|code|spark ssh|spark start|github push]" ;;
esac
CLI
chmod +x ~/forge/forge
grep -q 'forge' ~/.zshrc || echo 'export PATH="$HOME/forge:$PATH"' >> ~/.zshrc

echo -e "${B}[6/6]${N} Setting up DGX Spark..."
ssh -o ConnectTimeout=5 ${SPARK_USER}@${SPARK_IP} "mkdir -p /opt/forge" 2>/dev/null && \
ssh ${SPARK_USER}@${SPARK_IP} "cat > /opt/forge/docker-compose.yml" << 'COMPOSE'
version: '3.8'
services:
  vllm:
    image: vllm/vllm-openai:latest
    runtime: nvidia
    ports: ["8000:8000"]
    command: --model Qwen/Qwen2.5-Coder-32B-Instruct --quantization fp8 --max-model-len 32768 --host 0.0.0.0
    restart: unless-stopped
  whisper:
    image: fedirz/faster-whisper-server:latest-cuda
    runtime: nvidia
    ports: ["8002:8000"]
    restart: unless-stopped
  comfyui:
    image: yanwk/comfyui-boot:latest
    runtime: nvidia
    ports: ["8188:8188"]
    restart: unless-stopped
COMPOSE

wait
echo -e "\n${G}✓ FORGE installed!${N}\n"
echo "Run: source ~/.zshrc && forge status"
