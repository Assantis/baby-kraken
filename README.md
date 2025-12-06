# Baby Kraken 🐙

This is just a small bash script that I use for a very simple git flow.
A simple little helper that keeps my in check before pressing any buttons.

How the flow looks:
- Feature branches will get merged into develop
- When a release is considered complete develop is merged into master
- Hotfixes are going directly master ( also means you should branch off from master )
- After a hotfix the script attempts to merge back into develop
- Every push to master is tagged accordingly

The script has a dry run option to tell you what it would execute:
```
./baby-kraken.sh --dry-run
```