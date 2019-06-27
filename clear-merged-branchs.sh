#!/bin/bash
# description      : Delete local and remote branchs which its all commits are included in master branch of remote repository.
# author           : ElliotMok
# version          : 0.0.1-SNAPSHOT
# notes            : 1) This script is only suit for the git repository which has only one remote.
#                    2) Currently this script is only tested under git version "2.20.1.windows.1".

echo -n "Are you sure to delete local and remote branchs which its all commits are included in master branch of remote repository? [ENTER 'y' or 'n']:"
read confirm_to_execute
if [ $confirm_to_execute == n ];then
	echo exit!
	exit
fi



# 获取远程仓库名称和远程master分支名
remote_name=$(git remote)
remote_master_branch_name="$remote_name/master"
# 获取所有分支名称（利用git branch -a的输出，去掉标识当前分支的*号后，转化为数组类型）
branchs_str=$(git branch -a | sed 's/*//g')
branchs=($branchs_str)

# 遍历所有分支
for branch in ${branchs[*]}
do
  #track自master的本地分支，和远程master分支本身除外
  corresponding_remote_branch_name=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch")
  if [[ $corresponding_remote_branch_name == $remote_master_branch_name || $branch == "remotes/$remote_master_branch_name" ]];then 
	continue
  fi
  

  # 通过比对当前分支和远程master的commit差集，来判断该分支是否已经完全merge了
  log_differ="git log $branch ^$remote_name/master"
  # 如果是，则删除当前分支
  if [[ -z $(eval $log_differ) ]]; then
	if [[ $branch =~ ^remotes ]]; then
		echo -n "Are you sure to delete the branch \"$branch\" [ENTER 'y' or 'n']: "
		read confirm_to_delete_branch
		if [[ $confirm_to_delete_branch == y ]]; then
			delete_remote_branch_command="git push --delete $remote_name $(echo $branch | sed 's/remotes\/origin\///g')"
			echo "[executing command] $delete_remote_branch_command"
			eval $delete_remote_branch_command
		fi
	else
		delete_local_branch_command="git branch -d $branch"
		echo "[executing command] $delete_local_branch_command"
		eval $delete_local_branch_command
	fi
  fi
done
echo finish!