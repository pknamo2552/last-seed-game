# คลาสแม่สำหรับวัตถุทุกชิ้นในเกมที่ผู้เล่นสามารถกดอินเตอร์แอกต์ (โต้ตอบ) ได้
class_name Interactable
extends StaticBody3D

@export var prompt_message: String = "Press E to interact"

# ฟังก์ชันนี้จะปล่อยว่างไว้ เพื่อให้คลาสลูก (เช่น ประตู, เตียง, เครื่องปั่นไฟ) ไปเขียนคำสั่งของตัวเอง
func interact(player: CharacterBody3D) -> void:
	pass

# ฟังก์ชันสำหรับส่งคืนข้อความแสดงผลบนหน้าจอ UI ของผู้เล่น
func get_prompt(player: CharacterBody3D) -> String:
	return prompt_message
