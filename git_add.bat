set /p msg= "Commit Message: "
git add *
git status
git commit -m "%msg%"
git push -u origin main
pause