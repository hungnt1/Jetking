
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


## 2. Xây dựng VPN SSL Tunnel trên pfSense

### 2.1 : Mô hình triển khai
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
- D

- Truy cập WEB UI tại `https://{ip_wan}` với user : admin và password : pfsense 
Sau khi truy cập có thể cài đặt một số thông số cơ bản ( bỏ qua bước này )
