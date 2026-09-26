import os
import shutil
import zipfile
import xml.etree.ElementTree as ET
import mobi
import html2text

# Input book filename
input_azw3 = "dokumen.pub_designing-data-intensive-applications-the-big-ideas-behind-reliable-scalable-and-maintainable-systems-9781491903100-9781449373320-1491903104.azw3"
output_md = "DDIA_Book.md"

print(f"1. Extracting book contents from {input_azw3}...")
temp_dir, extracted_path = mobi.extract(input_azw3)

# Configure html2text converter optimized for AI agents and readability
converter = html2text.HTML2Text()
converter.ignore_links = False
converter.ignore_images = True
converter.body_width = 0

try:
    if zipfile.is_zipfile(extracted_path):
        print("2. Extracted format is EPUB container. Reading OPF manifest and spine...")
        with zipfile.ZipFile(extracted_path, 'r') as z:
            # Find OPF file
            opf_path = None
            for name in z.namelist():
                if name.endswith('.opf'):
                    opf_path = name
                    break
            
            if opf_path:
                opf_data = z.read(opf_path)
                root = ET.fromstring(opf_data)
                manifest = {item.attrib['id']: item.attrib['href'] for item in root.findall('.//{*}item') if 'id' in item.attrib and 'href' in item.attrib}
                spine_ids = [itemref.attrib['idref'] for itemref in root.findall('.//{*}itemref') if 'idref' in itemref.attrib]
                
                opf_dir = os.path.dirname(opf_path)
                md_sections = []
                print(f"3. Converting {len(spine_ids)} chapters/sections to clean Markdown...")
                for item_id in spine_ids:
                    if item_id in manifest:
                        rel_href = manifest[item_id]
                        full_entry = f"{opf_dir}/{rel_href}".replace('\\', '/') if opf_dir else rel_href
                        if full_entry in z.namelist():
                            html_raw = z.read(full_entry).decode('utf-8', errors='ignore')
                            section_md = converter.handle(html_raw).strip()
                            if section_md:
                                md_sections.append(section_md)
                
                full_content = "\n\n---\n\n".join(md_sections)
            else:
                print("⚠️ No OPF manifest found. Extracting XHTML files directly...")
                html_files = sorted([f for f in z.namelist() if f.endswith(('.html', '.xhtml'))])
                md_sections = []
                for f in html_files:
                    html_raw = z.read(f).decode('utf-8', errors='ignore')
                    section_md = converter.handle(html_raw).strip()
                    if section_md:
                        md_sections.append(section_md)
                full_content = "\n\n---\n\n".join(md_sections)
    else:
        print("2. Extracted format is raw HTML. Reading file...")
        try:
            with open(extracted_path, 'r', encoding='utf-8') as f:
                html_content = f.read()
        except UnicodeDecodeError:
            with open(extracted_path, 'r', encoding='latin-1', errors='ignore') as f:
                html_content = f.read()
        
        print("3. Converting HTML to clean Markdown...")
        full_content = converter.handle(html_content)

    print(f"4. Writing clean Markdown output to {output_md}...")
    with open(output_md, 'w', encoding='utf-8') as f:
        f.write(full_content)

    file_size_mb = os.path.getsize(output_md) / (1024 * 1024)
    print(f"[OK] Successfully generated clean, structured Markdown: {output_md} ({file_size_mb:.2f} MB)")

finally:
    # Cleanup temporary extraction directory
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir, ignore_errors=True)