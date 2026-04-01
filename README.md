# zeus-chat
Custom implementation of the Roblox chat system


![zeus chat gif](https://github.com/the8bitbyte/zeus-chat/blob/main/resources/zc.gif?raw=true)

> [!WARNING]
> Using this project in a game violates Roblox's community guidelines, use at your own risk

## about
Zeus chat was originally designed as a chat filter bypass tool about a year ago. The idea back then was just Intercept chat messages > relay through remote event > make it look real. This made sense as it was designed with legacy chat in mind. As legacy chat was removed, that implementation died.
Instead of intercepting chat messages, modern Zeus chat simply uses a custom chat input bar. With time it became clear that it lacked a lot of quality of life features the official one had. The good news is, since it was a custom implementation, adding features wasn't difficult at all. It didn't take long for Zeus chat to surpass the original chat bar in the context of quality of life.

## features
+ Emoji support
+ Integration with Adonis admin
+ Chat history navigation
+ Modular autocomplete
  + Autocompleate based on word frequency
  + Emoji name autocomplete
  + Player name autocomplete
  + Adonis commands autocomplete
+ [Dynamic code loading](#dcl-anchor)





<a name="dcl-anchor"></a>
### Dynamic Code loading
Zeus chat loads some files from a web server when the game runs. This is in attempt to obfuscate the code from Roblox, hopefully making the game less likely to be banned. This code isn't open sourced yet, but ill release it soon for transparency



Create an issue or join the discord for help and support
https://discord.gg/TRrBk3XP


