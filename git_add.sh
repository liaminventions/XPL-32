#!/bin/bash
echo "Commit Message: "
read MSG
git add *
git status
git commit -m "$MSG"
git push -u origin main
