

# Cài đặt, cấu hình pfSense VPN Tunnel cho DMZ ZOE


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

## 2.1 : Mô hình triển khai
![](https://i.imgur.com/sQMW2AP.png)

## 2.2 . Cài đặt pfSense 

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
![](https://i.imgur.com/ZXspqlY.png)
![](https://i.imgur.com/hIRHE4l.png)
- Truy cập vào giao diện WEB
![](https://i.imgur.com/1lqpjjf.png)

NOTE : 
- Khi thiết lập pfSense mà không thể truy cập vào giao diện LAN, có một số tùy chọn để cho phép truy cập vào webinterface. bằng cổng WAN
B1: Tắt `packet filter` bằng `pfctl d` :`pfctl` sẽ tự động bật lại khi set rule mới 

** Nên set rule mới khi đã vào đc WEB UI để đảm bảo có thể truy cập từ WAN Interface**
![](https://i.imgur.com/agxOL97.png)
B2; Tạo một rule mới `easyrule` truy cập Web UI
![](https://i.imgur.com/rob8par.png)
- Trong đó :
	- `easyrule pass wan tcp any any 443` : cho phép truy cập WEB UI đến WAN 443
	- `easyrule pass wan tcp any any 80` : cho phép truy cập WEB UI đến WAN 80
	- `easyrule pass wan icmp any any` : cho phép ping đến cổng WAN

- Cài đặt IP cho LAN Interface cho pfSense
![](https://i.imgur.com/oR4yxQ4.png)
- Cài đặt trên Windown Server 2012
![](https://i.imgur.com/V5T9bBe.png)
- Truy cập WEB UI tại `https://192.168.230.254` với user : admin và password : pfsense 
Sau khi truy cập có thể cài đặt một số thông số cơ bản ( bỏ qua bước này )
![](https://i.imgur.com/9TMR4bN.png)

- Do quá đây quá trình làm LAB nên cần cấu hình `Reserved Networks` tại `Interface -> WLAN`
![](https://i.imgur.com/xndRyfS.png)
## 2.3. Cài đặt OpenVPN SSL Remote access

### 2.3.1:  Khởi tạo Certificate trên Pfsense

- Khởi tạo một CA tại `System -> Cert. Manager->CA`
![](https://i.imgur.com/TRvV4Q9.png)
![](https://i.imgur.com/PWyn9BI.png)
- Khởi tạo một Server CE từ CA đã tạo  tại `System -> Cert. Manager->Certificate`
![](https://i.imgur.com/mKFhsLj.png)
![](https://i.imgur.com/GnuR0FN.png)

### 2.3.2: Khởi tạo OpenVPN Server SSL Remote Access
- Tạo một VPN Server tại `VPN -> OPENVPN -> Server `

- **General Information**
![](https://i.imgur.com/i0kmOHs.png)
- **Cryptographic Settings**
![](https://i.imgur.com/ubJ8rFw.png)

	Trong đó  :
	- Peer Certificate Authority : CA đã  **internal-ssl**tạo từ trước
	- Server certificate : CE của CA **internal-ssl** đã tạo từ trước 
- **Tunnel Setting**
![](https://i.imgur.com/VBN00uK.png)
	Trong đó : 
	- IPv4 Tunnel Network : dải  mạng  sử dụng cho VPN Tunnel
	- IPv4 Local network: subnet , hoặc địa chỉ IP có thể tham gia vào Tunnel, chấp nhận các kết nối từ xa
- **Client Setting**
![](https://i.imgur.com/AegF1xH.png)

- **Advanced Configuration** : cấu cấu hình bổ sung ( bỏ qua ) 


### 2.3.3: Cấu hình Rule cho OPENVPN

- Trên Interface WAN mở cổng UDP/1194 để có thể tạo kết nối VPN 
![](https://i.imgur.com/Ph57mJu.png)

- Trên Openvpn Interface tạo một Rule `any any` để chấp nhận mọi kết nối qua Tunnel
![](https://i.imgur.com/lIFMK11.png)
### 2.3.4: Xuất cấu hình cho OPENVPN Client

- Tạo User và CE trên pfSense tại `System -> User manager `
![](https://i.imgur.com/8rcSbAl.png)
![](https://i.imgur.com/XuL6UgN.png)
- Cài đặt `OpenVPN` plugin cho pfSense
![](https://i.imgur.com/BcdtxMH.png)
- Export Openvpn Windows Installer cho User `it2` tại `VPN->OpenVPN->Client Export`
![](https://i.imgur.com/tDkj5Ie.png)



 # 3 :  Thực hiện kết nối trên Computer Client

*OpenVP Client yêu cầu DOT NET Framework từ 4.0 trở lên*
- Cài đặt Package đã được Export từ pfSense
![](https://i.imgur.com/1T8aHL6.png)
![](https://i.imgur.com/dUabpIX.png)

- Quá trình cài đặt sẽ cài đặt thêm `Tap Driver` , chọn `install` để OPENVPN Client có thể họat động
![](https://i.imgur.com/z4iXAco.png)

![](https://i.imgur.com/x0agRaG.png)

- Mở phần mềm , double click vào icon ở góc phải. Xuất hiện một màn hình login. Sử dụng user và password được cấp phát từ pfSense OpenVPN Server
![](https://i.imgur.com/gOmzagD.png)

- Sau khi kết nối thành công sẽ có kết quả như sau :
![](https://i.imgur.com/9ZN9EZF.png)

- Kiểm tra Network adapter
![](https://i.imgur.com/NaAslAg.png)
Trong đó : đã xuất hiện một TUN interface nắm trong Subnet Tunnel đã cấu hình từ trước `10.22.20.0/24`

- Kiểm thử đương đi của gói tin khi đến Windows Server 2012 đứng sau pfSense
![](https://i.imgur.com/UNpejA3.png)
Trong đó : Gói tin đi đến Gateway của Tunnel đã cài đặt từ trước. 

- Kiểm thử `Remote Desktop`  đến Windows Server 
![](https://i.imgur.com/VogEBK4.png)
