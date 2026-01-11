#!/usr/bin/env Rscript
# Fix Corrupted R Packages
# This script reinstalls corrupted packages

cat("==========================================================\n")
cat("Fixing Corrupted R Packages\n")
cat("==========================================================\n\n")

# Remove and reinstall the corrupted cli package
cat("Step 1: Removing corrupted 'cli' package...\n")
remove.packages("cli")

cat("\nStep 2: Reinstalling 'cli' package...\n")
install.packages("cli", dependencies = TRUE, repos = "https://cloud.r-project.org/")

cat("\nStep 3: Verifying installation...\n")
library(cli)

cat("\n✓ Package 'cli' successfully reinstalled!\n")
cat("\nYou can now run: source('install_dependencies.R')\n")
