# GitHub Action to delete a directory from a remote repository

### Example usage
```yaml
- name: Cleanup storybook directory 🧹
  uses: maaaathis/delete-remote-directory@v1
  env:
    API_TOKEN_GITHUB: YourAPITokenForTheTargetRepo
  with:
    target-github-username: yourName
    target-repository-name: yourRepo
    target-branch: main
    target-directory: "/yourDirectory/is/here"
    commit-message: "Cleaned up files"
```