set /p msg= "Commit Message: "
git add *
git status
git commit -m "generic commit - pay no mind"
git push -u origin main
pause