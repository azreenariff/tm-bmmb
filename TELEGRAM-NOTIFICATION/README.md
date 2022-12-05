## Telegram Alert Notification Setup and Configuration

**Step 1 - Set up a Telegram bot**

- First we need a bot to send out our notifications, so let’s just set up one.

- Go to your Telegram *(Best to use the web interface for this)*

- Search for the user ***@BotFather*** - start a conversation with the bot.
  - To create a new bot, enter the command `/newbot`
  - Give the bot a name *(this is not the username of the bot, we will come to this later)*. So make it something like ***Nagios notifications***
  - Next you will need to provide a username for the bot. It must end in ***bot***, and this will be the ID of the bot *(just like BotFather)*
    - This will make the bot searchable by anyone, so make it something only you know
    - The username needs to be unique, so adding a timestamp or at least the day will help. We will name the bot ***NagiosNotification20191219_bot*** for example.
  - Now your bot is almost done and you will get a confirmation from the ***@BotFather***.

  - Here you will get the URL to the bot and most important your ***API-Key***.
  - The bot itself is done now.

<br />

- For the bot to know where to send the notifications we need our ***Telegram ID*** or ***Group ID***.
  - Invite the bot to your Telegram group
    - Select `Info` on your Telegram group name in your Telegram app and invite the bot. ***Make sure you are admin of the Telegram group or there may be issues***.
  - Once the bot is in the Telegram group, write something in the Telegram group
    - **As yourself**, write something in the Telegram group.
  - Fetch the ***chat_id*** of the Telegram group
    - Fetch events from your bot by issuing below command on a Linux or Nagios XI host:

```
curl -Lk -i -X GET https://api.telegram.org/bot<API_KEY>/getUpdates
```

- Output will be something like:

```
"message":{"message_id":14,"from":{"id":300920731,"is_bot":false,"first_name":"Your","last_name":"Name","language_code":"en-US"},"chat":{"id":-123456789,"title":"My fancy Telegram group","type":"supergroup"},"date":1520901132,"text":"I like beer"}}]}
```

- Copy and save ***chat*** id, which in above example is `-123456789`

<br />

**Step 2 - Configure Nagios XI**

-  Next up we need to configure Nagios to send the notifications via this new telegram bot.

**NOTE:** This step can be skipped and just import the commands using **Step 4**

- For that, we will define two (2) new commands
  - One for the **host** state
  - One for **service** state

- Add new commands in Nagios XI with the following:
  - For Host Notification:
    - Create a new command of type **misc** command 
    - with a name like: `kpu-notify-host-by-telegram`
    - with Command Line as below:

```
/usr/bin/curl -Lk -I -X POST --data chat_id=$CONTACTPAGER$ --data parse_mode="markdown" --data text=”%60HOST: $HOSTNAME$%60 %0A%0A%60TYPE: $NOTIFICATIONTYPE$%60%0A%0A%60STATE: $HOSTSTATE$%60 %0A%0A%60ADDRESS: $HOSTADDRESS$%60 %0A%60DETAILS: $HOSTOUTPUT$%60 %0A%0A%60DATE/TIME: $LONGDATETIME$%60%0A%0A" https://api.telegram.org/bot1600687034:AAG5P-S8ndZZtQtyYWveeGP2-ZHltM-Ohfw/sendMessage
```

  - For Service Notification:
    - Create a new command of type **misc** command
    - with a name like: `kpu-notify-service-by-telegram`
    - with Command Line as below:

```
/usr/bin/curl -Lk -I -X POST --data chat_id=$CONTACTPAGER$ --data parse_mode="markdown" --data text="%60HOST: $HOSTNAME$%60 %0A%0A%60TYPE: $NOTIFICATIONTYPE$%60%0A%0A%60SERVICE: $SERVICEDESC$%60 %0A%0A%60ADDRESS: $HOSTADDRESS$%60 %0A%60STATE: $SERVICESTATE$%60 %0A%60DETAILS: $SERVICEOUTPUT$%60 %0A%0A%60DATE/TIME: $LONGDATETIME$%60%0A%0A" https://api.telegram.org/bot1600687034:AAG5P-S8ndZZtQtyYWveeGP2-ZHltM-Ohfw/sendMessage
```

- Please **NOTE** that you need to provide your own bot ***API key*** in the command - and you can change the text which is sent to your liking of course.

- Next, create a new contact to use this Notification Commands

**NOTE:** This step can be skipped and just import the contacts using **Step 5**

  - Use the **generic-contact** template 
  - Under `Pager Number`, key-in the user ***CHAT ID***

**NOTE:** Make sure to assign to both the ***Host & Service Notification*** Commands.

<br />

**Step 3 - Telegram Behind a Proxy**

- If you are behind a proxy *(mostly in an enterprise environment)* and your Nagios XI server isn’t directly connected to the internet, you need to change the curl command like below:

```
/usr/bin/curl -x '[user:password@]proxy-address[:port]' -X POST ...
```
<br />

**Step 4 - Add commands into Nagios XI**

```
cp commands.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```
<br />

**Step 5 - Add contact into Nagios XI**

**NOTE:** Make sure to change the `Pager Number` to the correct one accordingly

```
cp contacts.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```

**DONE!**

