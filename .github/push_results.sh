#!/bin/bash
# Push a results folder of this CI job to its own branch, so logs, tables,
# figures and models can be fetched with plain git.
# usage: .github/push_results.sh <folder> <branch>
# needs GITHUB_TOKEN, GITHUB_REPOSITORY, GITHUB_RUN_NUMBER in the environment
dir=$1
branch=$2
if [ ! -d "$dir" ]; then
  echo "push_results: no folder $dir"
  mkdir -p "$dir"
  echo "job produced no output folder" > "$dir/EMPTY.txt"
fi
tmp=$(mktemp -d)
cp -r "$dir" "$tmp/out"
cd "$tmp" || exit 1
git init -q
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A
git commit -q -m "CI output of run ${GITHUB_RUN_NUMBER} [skip ci]"
git push -q -f "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" \
  "HEAD:refs/heads/${branch}"
echo "push_results: $dir -> $branch"
