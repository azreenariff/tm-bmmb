**1.** Create the agent in the group in the **_dwservice.net_** portal
- Open a browser on your remote PC
- Go to https://www.dwservice.net/
  - You need to have an account on **_dwservice.net_**. If not, create one first
- Create an agent
- **_Copy_** or **_take note_** of the `Agent Number` it gives out.  This will be required during installation

**2.** Install `dwagent` - Log into GUI on your Linux box - open the terminal and issue commands below

```
cd /usr/src
wget https://www.dwservice.net/download/dwagent_x86.sh
chmod +x dwagent_x86.sh
./dwagent_x86.sh
```
- Accept the default options, and when it asks if you want to create an agent or enter a code, choose `enter a code`
- Enter the `nine-digit code` you were given earlier.  You can include or omit the dashes

**3.** check & confirm `dwagent` service is running & enabled

```
systemctl status dwagent.service
systemctl is-enabled dwagent.service
```

**4.** Access the Linux box from remote
- Open a browser on your remote PC
- Go to https://www.dwservice.net/
- Login and you should see the listing of your agents to access


**DONE!**

