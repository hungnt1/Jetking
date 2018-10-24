


# Cài đặt, cấu hình pfSense OpenVPN SSL kết nối  DMZ ZONE trên 2 Site


## 1. Giới thiệu pfSense

## 1.1 . pfSense là gì ?
PfSene được biết đến là một tường lửa mềm, một dự án nguồn mở dựa trên nền tảng hệ điều hành FreeBSD và được sử dụng như một tường lửa hoặc một thiết bị định tuyến. Chris Buechler và Scott Ullricha hai tác giả sáng lập dự án m0n0wall năm 2004. Tuy nhiên tại thời điểm 2004, tác giả phải gặp vấn đề khó khăn khi mã nguồn của họ không tương thích tốt với các giải pháp tích hợp phần cứng (các thiết bị sử dụng 64MB RAM). PfSense với sự phát triển theo thời gian đã hỗ trợ rộng rãi các nền tảng phần cứng khác nhau và được sự đóng góp to lớn từ cộng động sử dụng mã nguồn mở thế giới.. PfSense yêu cầu cấu hình phần cứng thấp nên phù cho việc tích hợp vào các thiết bị tích hợp khác nhau nhằm tăng tính linh động và hiệu suất trong quá trình vận hành.. Ngoài ra pfSense được tích hợp thêm WEB UI dễ dàng trong việc quản lý .

## 1.2. Các chứng năng của pfSense
- Cung cấp WebGUI dễ dàng cho việc quản lý
- Cung cấp nền tảng tường lửa mạnh mẽ trên FreeBDS
- Cung cấp giải pháp định tuyến 
- Cung cấp giải pháp DNS , DHCP Server
- Cung cấp giải pháp VPN Tunnel
- Cung cấp giải pháp Wireless Portal


# 2. Xây dựng VPN SSL Tunnel trên pfSense

## 2.1. Mô hình triển khai Site to Site
![](https://i.imgur.com/SJjzhAi.png)

## 2.2 . Cài đặt pfSense trên 2 SITE

Có thể cài đặt pfSense nhiều phiên bản khác nhau trên trường khác nhau 
Tải ISO tại : https://www.pfsense.org/download/
Việc cài đặt pfSense trên phần cứng giống như việc cài các OS khác

- Chuẩn bị tối thiểu 2 network interface trên phần cứng. 
Trong đó :
	- 1 : WAN CARD, giao tiếp với mạng ngoài
	- 2 : LOCAL CARD, giao tiếp, định tuyến các host nội bộ
![](https://i.imgur.com/wF4Cqy2.png)

- Quá trình cài đặt pfSense step by step
![](https://i.imgur.com/wot5i4C.png)
![](https://i.imgur.com/mOqy6BX.png)

- Sau khi cài đặt xong , cần `Reboot` lại host và vào diện UNIX chính của pfSense
![](https://i.imgur.com/jpvK9zC.png)

- Giao diện UNIX chỉnh sủa pfSense
![](https://i.imgur.com/Efj27f2.png)

- Dựa vào MAC Address của cổng mạng để chọn WAN interface và LAN interface 
![](https://i.imgur.com/VszWDU2.png)
![](https://i.imgur.com/hIRHE4l.png)

- Truy cập vào giao diện WEB
![](https://i.imgur.com/1lqpjjf.png)
## 2.3. Cấu hình IP trên SITE Hà Nội
- Cài đặt IP cho LAN Interface cho pfSense
![](https://i.imgur.com/oR4yxQ4.png)
- Cài đặt trên IP trên  Windows Server 2012
![](https://i.imgur.com/V5T9bBe.png)
- Truy cập WEB UI tại `https://192.168.230.254` với user : admin và password : pfsense 
Sau khi truy cập có thể cài đặt một số thông số cơ bản ( bỏ qua bước này )
![](https://i.imgur.com/9TMR4bN.png)

- Do quá đây quá trình làm LAB nên cần cấu hình `Reserved Networks` tại `Interface -> WLAN`
![](https://i.imgur.com/xndRyfS.png)

## 2.4. Cấu hình IP trên Site HCM

- Cấu hình IP trên pfSense
![](https://i.imgur.com/OnXjBXG.png)


- Cấu hình IP trên Windows Server 2012
![](https://i.imgur.com/HAB7eiy.png)
- Truy cập WEB UI tại `https://192.168.230.254` với user : admin và password : pfsense 
Sau khi truy cập có thể cài đặt một số thông số cơ bản ( bỏ qua bước này )
![](https://i.imgur.com/9TMR4bN.png)

- Do quá đây quá trình làm LAB nên cần cấu hình `Reserved Networks` tại `Interface -> WLAN`
![](https://i.imgur.com/xndRyfS.png)

NOTE : 
- Khi thiết lập pfSense mà không thể truy cập vào giao diện LAN, có một số tùy chọn để cho phép truy cập vào WEB UI. bằng cổng WAN
B1: Tắt `packet filter` bằng `pfctl d` :`pfctl` sẽ tự động bật lại khi set rule mới 
**Nên set rule mới khi đã vào đc WEB UI để đảm bảo có thể truy cập từ WAN Interface**
![](https://i.imgur.com/agxOL97.png)
B2; Tạo một rule mới `easyrule` truy cập Web UI
![](https://i.imgur.com/rob8par.png)
- Trong đó :
	- `easyrule pass wan tcp any any 443` : cho phép truy cập WEB UI đến WAN 443
	- `easyrule pass wan tcp any any 80` : cho phép truy cập WEB UI đến WAN 80
	- `easyrule pass wan icmp any any` : cho phép ping đến cổng WAN

## 2.5. Cài đặt OpenVPN SSL trên SITE Hà Nội

### 2.5.1.  Khởi tạo Certificate trên Pfsense

- Khởi tạo một CA tại `System -> Cert. Manager->CA`
![](https://i.imgur.com/TRvV4Q9.png)
![](https://i.imgur.com/PWyn9BI.png)

- Khởi tạo một Server CE từ CA đã tạo  tại `System -> Cert. Manager->Certificate`
![](https://i.imgur.com/mKFhsLj.png)
![](https://i.imgur.com/GnuR0FN.png)

-   Tạo User `it2` và CE cho user `it2` trên pfSense tại  `System -> User manager`[![](https://camo.githubusercontent.com/923df6997f87b650e834e70bad5e8a229ba68dd3/68747470733a2f2f692e696d6775722e636f6d2f3872635362416c2e706e67)](https://camo.githubusercontent.com/923df6997f87b650e834e70bad5e8a229ba68dd3/68747470733a2f2f692e696d6775722e636f6d2f3872635362416c2e706e67)[![](https://camo.githubusercontent.com/2a8e7b2fef32df16f185366051fe232695d46c7d/68747470733a2f2f692e696d6775722e636f6d2f58754c3655674e2e706e67)](https://camo.githubusercontent.com/2a8e7b2fef32df16f185366051fe232695d46c7d/68747470733a2f2f692e696d6775722e636f6d2f58754c3655674e2e706e67)
	Trong đó :
	- `it-ce-internal-ssl` : sử dụng tài khoản để xác thực chính CE này
	
### 2.5.2. Khởi tạo OpenVPN Server SSL Peer to Peer 
- Tạo một VPN Server tại `VPN -> OPENVPN -> Server`

** Cấu hình **

- **General Information**
![](https://i.imgur.com/NKnaRRA.png)
	Trong đó
	- Server mode : Peer to Peer 
	- Protocol : UDP IPv4 - sử dụng UDP là giao thức transport 
	- Device node :  cấu hình mode TUN, TAP trên interface  tunnel 
	- Interface : WAN - sử dụng card WAN để interface tunnel liên kết vào
	- Local Port : cổng truyền dữ liệu cho tunnel

- **Cryptographic Settings**
![](https://i.imgur.com/1CthaCd.png)	
	Trong đó :
	- Peer Certificate Authority : CA để chứng thực giữa 2 site
	- Server Certificate : CE được sử dụng cho Server
- **Tunnel Settings**
![](https://i.imgur.com/gykxq3b.png)
	Trong đó :
	- IPv4 Tunnel Network : Subnet sử dụng cho Tunnel , bao gồm tunnel gateway và các client
	- IPv4 Local Network : Subnet có thể tham gia vào Tunnel, có thể remote từ các site khác
	- IPv4 Remote Network : Subnet site HCM có thể tham gia vào Tunne

- Sau khi tạo cấu hình xong, sẽ xuất hiện 1 Network Port `ovpns1()`, gắn Port vào một interface và enable
![](https://i.imgur.com/PoIF1h0.png)
![](https://i.imgur.com/dj7c31D.png)
### 2.5.3. Cấu hình Rule cho OPENVPN

-   Trên Interface WAN mở cổng UDP/1194 để có thể tạo kết nối VPN  [![](https://camo.githubusercontent.com/75a5a29897168bc0dd49d1f139eaa476bd4b620b/68747470733a2f2f692e696d6775722e636f6d2f506835376d4a752e706e67)](https://camo.githubusercontent.com/75a5a29897168bc0dd49d1f139eaa476bd4b620b/68747470733a2f2f692e696d6775722e636f6d2f506835376d4a752e706e67)
    
-   Trên OPENVPN Interface tạo một Rule  `any any`  để chấp nhận mọi kết nối qua Tunnel  [![](https://camo.githubusercontent.com/8f5e8772401843ff538920ca46c1719d3a71ff5b/68747470733a2f2f692e696d6775722e636f6d2f6c49464d4b31312e706e67)](https://camo.githubusercontent.com/8f5e8772401843ff538920ca46c1719d3a71ff5b/68747470733a2f2f692e696d6775722e636f6d2f6c49464d4b31312e706e67)

## 2.6. Cài đặt OpenVPN SSL Client trên SITE HCM

### 2.6.1.  Lưu thông tin CA và CE  và TLS Key từ site Hà Nội

- *Có thể sử dụng Notepad hoặc editor bất kì để lưu lại dữ liệu cho quá trình cài đặt*

- Để có thể lấy thông tin của CA, sử dụng `Action -> Edit CA` , sau đó lưu tại `Certificate data` và `Certificate Private Key` từ  `internal-ssl` 
![](https://i.imgur.com/iAQOXjv.png)

- Để có thể lấy thông tin của CE `it-ce-internal-ssl` của user `it2`
	Trong đó 
	- Để lấy `Certificate Data` sử dụng `Action -> Export Certificate`,  lưu file dưới dạng *.txt và lưu dữ liệu lại
	-  Để lấy `Private Data` sử dụng `Action -> Export Key` , lưu lại dữ liệu trong file 
![](https://i.imgur.com/jalbRZG.png)

- Lưu `TLS Key` của OpenVPN Server tại  `VPN -> OpenVPN -> Server -> Action -> Edit -> TLS Key`


### 2.6.2. Khởi tạo CA và CE mới từ các KEY của Site Hà Nội

-  Sử dụng `Certificate data` và `Certificate Private Key` được lưu lại từ Site Hà Nội để tạo một CA mới
![](https://i.imgur.com/zyQ0VuU.png)

- Sử dụng CE `Certificate data` và `Private key data` được Export từ Site Hà Nội để tạo một CE mới
![](https://i.imgur.com/ZByDzfg.png)

- CA và CE sau khi tạo thành công
![](https://i.imgur.com/2OWOXML.png)
![](https://i.imgur.com/dxuKUXj.png)

### 2.6.3. Cấu hình OpenVPN SSL Client

- Tạo một điểm Client mới tại `VPN -> OpenVPN -> Clients -> Add`

**Cấu hình**

- **General Information**
![](https://i.imgur.com/8aHASmL.png)
	Trong đó :
	- Server mode : mode Peer to Peer server đang sử dụng
	- Server host or address : địa chỉ IP WAN của Site Hà Nội
	- Server port : port OpenVPN mà Site Hà Nội đang sử dụng
- `User Authentication Settings`
![](https://i.imgur.com/SwleQHZ.png)
	Trong đó :
	- username : tài khoản xác thực CE `it-ce-internal-ssl`trên Site Hà Nội
	- password : mật khẩu của tài khoản trên

- **Cryptographic Settings**
![](https://i.imgur.com/2DEN6tY.png)
	Trong đó :
	- TLS Key : sử dụng TLS Key được export từ Site Hà Nội
	- Peer Certificate Authority : CA được Export data từ Site Hà Nội
	- Client Certificate : CE được Export data từ Site Hà Nội ( quan trọng : được xác thực bởi username và password tại `User Authentication Settings`)

- **Tunnel Settings**
![](https://i.imgur.com/Qonn7iq.png)
Trong đó : 
	- IPv4 Tunnel Network : Subnet Tunel được sử dụng trên Site Hà Nội
	- IPv4 Remote Network : Network từ site Hà Nội có thể tham gia tunnel  ( mạng LAN ) 

- Sau khi tạo cấu hình xong, sẽ xuất hiện 1 Network Port `ovpns1()`, gắn Port vào một interface và enable
![](https://i.imgur.com/PoIF1h0.png)
![](https://i.imgur.com/dj7c31D.png)

# 3. Kiểm tra, xác thực kết nối

- Để kiểm tra kết nối thành công . Trên Site HCM sử dụng `Status -> OpenVPN ` kiểm tra
![](https://i.imgur.com/fGZ3R27.png) 

- Kiểm tra trên Hà Nội
![](https://i.imgur.com/5ck1PV3.png)

- Kiểm tra Ping từ Server về HCM
![](https://i.imgur.com/znDAUdW.png)

- Kiểm tra Ping Client từ HCM về Hà Nội
![](https://i.imgur.com/ViKDl2D.png)
