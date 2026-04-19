"""
Remove 'const' from Dart expressions that contain AppTheme. references.
Since AppTheme colors are now getters (not compile-time constants),
any const expression tree containing AppTheme.xxx must have const removed.
"""
import re
import os
import glob

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'AppTheme.' not in content:
        return 0
    
    # Find all 'const ' followed by a constructor (capital letter or lowercase for things like 'const [')
    pattern = re.compile(r'\bconst\s+(?=[A-Z])')
    
    removals = []
    for match in pattern.finditer(content):
        start = match.start()
        end = match.end()
        
        # Find the opening paren after the constructor name
        paren_start = content.find('(', end)
        if paren_start == -1:
            continue
        
        # Make sure there's only constructor name chars between end and paren
        between = content[end:paren_start]
        # Allow letters, digits, dots (for named constructors like ColorScheme.dark), 
        # underscores, angle brackets (generics), spaces/newlines
        if not re.match(r'^[\w.<>,\s]*$', between):
            continue
        
        # Find matching closing paren
        depth = 1
        i = paren_start + 1
        while i < len(content) and depth > 0:
            ch = content[i]
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            # Skip string literals
            elif ch == "'" or ch == '"':
                quote = ch
                i += 1
                while i < len(content) and content[i] != quote:
                    if content[i] == '\\':
                        i += 1  # skip escaped char
                    i += 1
            i += 1
        
        if depth != 0:
            continue
        
        # Check if AppTheme. appears in the constructor's argument block
        block = content[paren_start:i]
        if 'AppTheme.' in block:
            removals.append((start, end))
    
    if not removals:
        return 0
    
    # Remove from end to start so positions don't shift
    for start, end in reversed(removals):
        content = content[:start] + content[end:]
    
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        f.write(content)
    
    return len(removals)

base = r"C:\Users\harsh\OneDrive\Desktop\rentit\frontend\lib"
total = 0
for filepath in glob.glob(os.path.join(base, "**", "*.dart"), recursive=True):
    count = process_file(filepath)
    if count > 0:
        rel = os.path.relpath(filepath, base)
        print(f"  {rel}: removed {count} const keywords")
        total += count

print(f"\nTotal: {total} const keywords removed")
