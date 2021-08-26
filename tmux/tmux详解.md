## 会话（session）
- 一个 Tmux 会话中可以包含多个窗口。
    1. 在会话外创建一个新的会话：
    `tmux new -s <name-of-my-session>`
    2. 进入会话后创建新的会话,只需要按下 `Ctrl-b`，然后输入如下的命令：
        ```
        Ctrl+Shift+a
        :new -s <name-of-my-new-session>
        ```
- 在 Tmux 的会话间切换
    1. 在会话内获取会话列表，可以按下`Ctrl+Shift+a s`。     
        下图所示的就是会话的列表：
        ```
        Ctrl+Shift+a s
        ```
        ![Image1](https://dengbanghan.oss-cn-shenzhen.aliyuncs.com/Image/tmux/Image1.jpeg)
    2. 列表中的每个会话都有一个 ID，该 ID 是从 0 开始的。按下对应的 ID 就可以进入会话。     
        在会话外获取会话列表：
        ```
        tmux ls
        ```
        在会话外进入会话：
        ```
        tmux attach -t <name-of-my-session> 或 tmux a -t <name-of-my-session>
        ```
    3. 进入列表中第一个会话
        ```
        tmux attach 或 tmux a
        ```
    4. 临时退出但不删除会话：
        ```
        Ctrl+Shift+a d
        ```
    5. 在会话内退出并删除session
        ```
        Ctrl+Shift+a 
        :kill-session
        ```
    6. 删除所有session
        ```
        Ctrl+Shift+a 
        :kill-server
        ```
    7. 在会话外删除指定session
        ```
        tmux kill-session -t <name-of-my-session>
        ```

## 窗口（Window）
- 一个 Tmux 会话中可以包含多个窗口，一个窗口中又可以放置多个窗格。  
    在 Tmux 的会话中，现有的窗口将会列在屏幕下方。  
    下图所示的就是在默认情况下 Tmux 列出现有窗口的方式。    
    这里一共有三个窗口，分别是“server”、“editor”和“shell”。
    ![Image2](https://dengbanghan.oss-cn-shenzhen.aliyuncs.com/Image/tmux/Image2.jpeg)

1. 创建窗口：
    ```
    Ctrl+Shift+a c
    ```
2. 查看窗口列表
    ```
    Ctrl+Shift+a w
    ```
3. 切换到指定窗口，只需要先按下Ctrl-b，然后再按下想切换的窗口所对应的数字。
    ```
    Ctrl+Shift+a 0
    ```
4. 切换到下一个窗口
    ```
    Ctrl+Shift+a n
    ```
5. 切换到上一个窗口
    ```
    Ctrl+Shift+a p
    ```
6. 在相邻的两个窗口里切换
    ```
    Ctrl+Shift+a l
    ```
7. 重命名窗口
    ```
    Ctrl+Shift+a ,
    ```
8. 在多个窗口里搜索关键字
    ```
    Ctrl+Shift+a f
    ```
9. 删除窗口
    ```
    Ctrl+Shift+a &
    ```

## 窗格(Panes)
- 一个tmux窗口可以分割成若干个格窗，并且格窗可以在不同的窗口中移动、合并、拆分。
1. 创建pane
    - 横切 split pane horizontal
        ```
        Ctrl+Shift+a -
        ```
    - 竖切 split pane vertical
        ```
        Ctrl+Shift+a |
        ```
2. 按顺序在pane之间移动
    ```
    Ctrl+Shift+a o
    ```
3. 上下左右选择pane
    ```
    Ctrl+Shift+a 方向键上下左右
    ```
4. 调整pane的大小   
    (按住Ctrl+Shift+a 再按 [上|下|左|右] 键也可以实现相同的效果)
    - 向上:
        ```
        Ctrl+Shift+a 
        :resize-pane -U 
        ```
    - 向下:
        ```
        Ctrl+Shift+a 
        :resize-pane -D 
        ```
    - 向左:
        ```
        Ctrl+Shift+a 
        :resize-pane -L
        ```
    - 向右:
        ```
        Ctrl+Shift+a 
        :resize-pane -R
        ```
    
    - 在上下左右的调整里，最后的参数可以加数字 用以控制移动的大小，例如：
        ```
        Ctrl+Shift+a 
        :resize-pane -D 5 #向下移动5行
        ```
    - 在同一个window里上下左右移动pane  
        往左边，往上面
        ```
        Ctrl+Shift+a { 
        ```
        往右边，往下面
        ```
        Ctrl+Shift+a } 
        ```
5. 删除pane
    ```
    Ctrl+Shift+a x
    ```
6. 更换pane排版（上下左右分隔各种换）
    ```
    Ctrl+Shift+a "空格"
    ```
7. 移动pane至新的window
    ```
    Ctrl+Shift+a !
    ```
8. 移动pane合并至某个window
    ```
    Ctrl+Shift+a :join-pane -t $window_name
    ```
9. 按顺序移动pane位置
    ```
    Ctrl+Shift+a Ctrl+o
    ```
10. 显示pane编号
    ```
    Ctrl+Shift+a q
    ```
11. 显示时间
    ```
    Ctrl+Shift+a t
    ```