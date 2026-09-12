import os
import mobi
import html2text

# اسم ملف الكتاب الأصلي عندك
input_azw3 = "dokumen.pub_designing-data-intensive-applications-the-big-ideas-behind-reliable-scalable-and-maintainable-systems-9781491903100-9781449373320-1491903104.azw3"
output_md = "DDIA_Book.md"

print("1. جاري استخراج محتوى الكتاب لوكال...")
temp_dir, html_filepath = mobi.extract(input_azw3)

print("2. جاري قراءة الملف وتجهيز التنسيق...")
# محاولة القراءة بـ UTF-8، وإذا فشل يتم الانتقال لترميز بديل مع تجاهل الأخطاء
try:
    with open(html_filepath, 'r', encoding='utf-8') as f:
        html_content = f.read()
except UnicodeDecodeError:
    print("⚠️ تم رصد ترميز مختلف، جاري القراءة بالترميز البديل الآمن...")
    with open(html_filepath, 'r', encoding='latin-1', errors='ignore') as f:
        html_content = f.read()

# إعداد محول الـ Markdown وتخصيصه عشان يكون مثالي للـ Agent
converter = html2text.HTML2Text()
converter.ignore_links = False   # الحفاظ على الروابط الداخلية والمراجع ليفهمها الإيجنت
converter.ignore_images = True   # تجاهل الصور تماماً لتقليل حجم الملف 
converter.body_width = 0         # منع المحول من قطع السطور تلقائياً للحفاظ على تماسك الجمل

print("3. جاري التحويل إلى Markdown (قد يستغرق لحظات لحجم الكتاب)...")
markdown_text = converter.handle(html_content)

# حفظ الملف النهائي بترميز UTF-8 نضيف وموحد
with open(output_md, 'w', encoding='utf-8') as f:
    f.write(markdown_text)

print(f"✔️ تم بنجاح! الملف النظيف الجاهز للإيجنت هو: {output_md}")