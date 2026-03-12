#!/bin/bash
#SBATCH --job-name=kitchen_zimage
#SBATCH --output=kitchen_zimage_%j.log
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --gpus-per-node=h100:1
#SBATCH --time=12:00:00
#SBATCH --mem=0
#SBATCH --mail-user=ys97@yorku.ca
#SBATCH --mail-type=ALL

set -euo pipefail

# Optional: adapt these module commands to your cluster environment
if command -v module >/dev/null 2>&1; then
  module purge || true
  module load StdEnv/2023 2>/dev/null || true
  module load python/3.10 2>/dev/null || true
  module load cuda/12.2 2>/dev/null || true
  # Optional: load a PyTorch module if available on this cluster
  module load pytorch/2.3.0 2>/dev/null || module load pytorch 2>/dev/null || true
fi

mkdir -p logs

# Work from the Slurm submit directory (contains script + kitchen_data.json)
cd "$SLURM_SUBMIT_DIR"

########################
# 1) Python environment #
########################

if [ ! -d ".venv" ]; then
  echo "ERROR: Python virtual environment .venv not found in $SLURM_SUBMIT_DIR." >&2
  echo "Create it and install dependencies on the login node before submitting this job." >&2
  exit 1
fi

source .venv/bin/activate

echo "Using Python: $(which python)"
python --version || true

########################
# 2) Environment vars   #
########################

# Hugging Face caches (must already be populated on login node)
export HF_HOME="${HF_HOME:-$SCRATCH/hf_home}"
export HF_HUB_CACHE="${HF_HUB_CACHE:-$HF_HOME/hub}"
mkdir -p "$HF_HUB_CACHE"

# Output root for generated assets (under /scratch/$USER/new_gen by default)
export OUTPUT_ROOT="${OUTPUT_ROOT:-$SCRATCH/new_gen/kitchen_images}"
mkdir -p "$OUTPUT_ROOT"

echo "HF_HOME: $HF_HOME"
echo "HF_HUB_CACHE: $HF_HUB_CACHE"
echo "Output root: $OUTPUT_ROOT"

########################
# 3) Run generation     #
########################

MODEL_NAME="Tongyi-MAI/Z-Image-Turbo"
KITCHEN_JSON="$SLURM_SUBMIT_DIR/flutter_app/assets/data/kitchen_data.json"

if [ ! -f "$KITCHEN_JSON" ]; then
  echo "ERROR: kitchen_data.json not found at $KITCHEN_JSON" >&2
  exit 1
fi

echo "Using model: $MODEL_NAME"
echo "Using kitchen JSON: $KITCHEN_JSON"

# Recommended for Z-Image Turbo: small step count, guidance_scale ~0
# (--true-cfg-scale is mapped to guidance_scale inside generate_kitchen_images_qwen.py)
python generate_kitchen_images_qwen.py \
  --kitchen-json "$KITCHEN_JSON" \
  --output-dir "$OUTPUT_ROOT" \
  --model "$MODEL_NAME" \
  --types ingredient tool action cuisine state transition block sprite \
  --steps 9 \
  --true-cfg-scale 0.0 \
  --seed 42 \
  --use-quality-presets \
  --video-prompts-json "$OUTPUT_ROOT/kitchen_video_prompts.json" \
  | tee "logs/kitchen_zimage_run_${SLURM_JOB_ID}.log"

echo "Slurm job complete."
