import cv2
import numpy as np
import os

# ==========================================
# CONFIGURACIÓN DEL ESTÁNDAR DE TU APP
# ==========================================
COLOR_PRIMARIO = "#4FD1C5"
GROSOR_LINEA = "2.5"

def procesar_y_escalar_svg(ruta_in, ruta_out, tipo):
    """
    Toma un recorte PNG/JPG, lo vectoriza y lo escala matemáticamente 
    para que encaje perfecto en el viewBox estandarizado de la app.
    """
    if not os.path.exists(ruta_in):
        print(f"⚠️ No se encontró: {ruta_in}")
        return

    # 1. Leer imagen y binarizar (Blanco y Negro puro)
    img = cv2.imread(ruta_in, cv2.IMREAD_GRAYSCALE)
    # Filtramos grises claros para intentar ignorar marcas de agua suaves
    _, thresh = cv2.threshold(img, 180, 255, cv2.THRESH_BINARY_INV)

    # 2. Encontrar contornos
    contornos, _ = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    if not contornos:
        print(f"⚠️ No se detectaron formas en: {ruta_in}")
        return

    # 3. Encontrar la caja delimitadora (Bounding Box) de TODOS los dibujos
    # para saber cuánto mide el gráfico real dentro del recorte
    todos_puntos = np.vstack(contornos)
    x_min, y_min, w_dibujo, h_dibujo = cv2.boundingRect(todos_puntos)

    # 4. Configurar el "Lienzo" según el estándar que definimos antes
    if tipo == "opcion":
        vb_w, vb_h = 90, 90
        margen = 15 # Margen interno para que no choque con el borde
    else: # secuencia
        vb_w, vb_h = 500, 130
        margen = 20

    # Calcular la escala para que el dibujo encaje en el nuevo viewBox
    escala = min((vb_w - margen*2) / w_dibujo, (vb_h - margen*2) / h_dibujo)
    
    # Calcular el offset (desplazamiento) para centrar el gráfico en el SVG
    offset_x = (vb_w - (w_dibujo * escala)) / 2 - (x_min * escala)
    offset_y = (vb_h - (h_dibujo * escala)) / 2 - (y_min * escala)

    # 5. Escribir el archivo SVG
    with open(ruta_out, "w", encoding="utf-8") as f:
        # Cabecera estándar
        f.write(f'<svg viewBox="0 0 {vb_w} {vb_h}" xmlns="http://www.w3.org/2000/svg">\n')
        
        # Si es una opción, dibujamos tu marco redondeado premium
        if tipo == "opcion":
            f.write(f'  <rect x="0" y="0" width="{vb_w}" height="{vb_h}" fill="none" stroke="{COLOR_PRIMARIO}" stroke-width="{GROSOR_LINEA}" rx="8"/>\n')
        
        # Grupo con los estilos
        f.write(f'  <g fill="none" stroke="{COLOR_PRIMARIO}" stroke-width="{GROSOR_LINEA}" stroke-linejoin="round">\n')

        # Procesar y escalar cada contorno
        for contorno in contornos:
            if cv2.contourArea(contorno) < 10: # Ignorar ruido o polvo pixelado
                continue
            
            # Suavizar el contorno
            epsilon = 0.002 * cv2.arcLength(contorno, True)
            aprox = cv2.approxPolyDP(contorno, epsilon, True)

            path_data = ""
            for i, punto in enumerate(aprox):
                # Aplicamos la escala y el centrado a cada punto
                x_real = (punto[0][0] * escala) + offset_x
                y_real = (punto[0][1] * escala) + offset_y
                
                # Redondeamos a 1 decimal para un código SVG más limpio
                x_str, y_str = round(x_real, 1), round(y_real, 1)

                if i == 0:
                    path_data += f"M {x_str} {y_str} "
                else:
                    path_data += f"L {x_str} {y_str} "
            
            path_data += "Z"
            f.write(f'    <path d="{path_data}" />\n')

        f.write('  </g>\n')
        f.write('</svg>\n')
    
    print(f"✅ Generado: {ruta_out}")

def generar_nivel_completo(carpeta_problema):
    """
    Busca los recortes en la carpeta y genera todos los SVGs estandarizados.
    """
    print(f"\n--- Procesando {carpeta_problema} ---")
    
    # Procesar secuencia
    procesar_y_escalar_svg(f"{carpeta_problema}/recorte_secuencia.png", f"{carpeta_problema}/secuencia.svg", "secuencia")
    
    # Procesar opciones
    letras = ['a', 'b', 'c', 'd', 'e']
    for letra in letras:
        ruta_in = f"{carpeta_problema}/recorte_{letra}.png"
        ruta_out = f"{carpeta_problema}/opcion_{letra}.svg"
        procesar_y_escalar_svg(ruta_in, ruta_out, "opcion")

# ==========================================
# INSTRUCCIONES DE USO
# ==========================================
if __name__ == "__main__":
    # Asegúrate de tener una carpeta llamada 'problema12' (o el número que sea)
    # y dentro coloca tus capturas recortadas limpias con estos nombres exactos:
    # - recorte_secuencia.png
    # - recorte_a.png
    # - recorte_b.png
    # - recorte_c.png
    # - recorte_d.png
    # - recorte_e.png
    
    carpeta_objetivo = "problema12" 
    
    # Crea la carpeta de prueba si no existe
    if not os.path.exists(carpeta_objetivo):
        os.makedirs(carpeta_objetivo)
        print(f"Se creó la carpeta '{carpeta_objetivo}'. Coloca allí tus recortes PNG y vuelve a ejecutar.")
    else:
        generar_nivel_completo(carpeta_objetivo)