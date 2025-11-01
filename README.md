<!--
      ／人◕ ‿‿ ◕人＼
   ✧･ﾟ: *✧･ﾟ:*　*ﾟ･✧*:･ﾟ✧
   ✧･ﾟ: *✧･ﾟ:*　*ﾟ･✧*:･ﾟ✧
        ip_mapper
   ✧･ﾟ: *✧･ﾟ:*　*ﾟ･✧*:･ﾟ✧
   ✧･ﾟ: *✧･ﾟ:*　*ﾟ･✧*:･ﾟ✧
-->

[![Shionji-Yuuko-1024-1054356.png](https://i.postimg.cc/vH8tJLVm/Shionji-Yuuko-1024-1054356.png)](https://postimg.cc/hhwmxmMF)

# ✨ IP Mapper ✨

Welcome to **IP Mapper**, a magical shell script that resolves domain IP addresses and reveals their enchanting relationships! ♰

## 🦄 What does it do?

- 🗺️ Maps domains to their corresponding IP addresses
- 🔍 Finds the most repetitive IPs (used by multiple domains)
- 🌟 Highlights the most unique IPs (used by only one domain)
- 🎀 Helps you understand which domains share a mystical bond via their IPs!

## 🚀 How to use

1. **Clone this repository:**
   ```sh
   git clone https://github.com/narukoshin/ip_mapper
   cd ip_mapper
   ```

2. **Prepare your list of domains**  
   Create a file (e.g. `domains.txt`) with one domain per line.

3. **Run the script:**
   ```sh
   chmod +x ip_mapper.sh
   ./ip_mapper.sh domains.txt

   # To save results in the file, you can use the following:
   ./ip_mapper.sh domains.txt results.txt
   ```

4. **View the results!**  
   You'll see which IPs are shared frequently and which are rare treasures.

## 🌸 Example Output

```py
Domains grouped by IP:

1.1.1.1 (2 domains)
  domain1.com
  domain2.com
  

1.2.1.1 (1 domain)
  domain3.com
  

Unique IPs (1 domain only):
  1.2.1.1 → domain3.com

Most repeated IP: 1.1.1.1 → 2 domains
  Domains: domain1.com domain2.com
```

## 💖 Features

- Pure shell magic (no dependencies!)
- Fast and lightweight
- Easy to customize

## 🫧 License

MIT — do what you love!

---

<p align="center">
  The project was sponsored by THE NEET FAMILY
</p>

<p align="center">
<img  src="https://emoji.discord.st/emojis/4611173b-be7a-47a8-b17d-46c2093c9009.gif" width="70" /> </p>
