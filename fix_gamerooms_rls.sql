-- Script para arreglar permisos en game_rooms
-- El problema es que el Host no recibe la notificación cuando el Guest se une.
-- Esto suele ser por políticas RLS restrictivas.

-- 1. Habilitar RLS (por si acaso)
ALTER TABLE public.game_rooms ENABLE ROW LEVEL SECURITY;

-- 2. Eliminar políticas antiguas que puedan causar conflicto
DROP POLICY IF EXISTS "Enable read access for all users" ON public.game_rooms;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.game_rooms;
DROP POLICY IF EXISTS "Enable update for users based on email" ON public.game_rooms;
DROP POLICY IF EXISTS "Public Access" ON public.game_rooms;

-- 3. Crear una política PERMISIVA para desarrollo
-- Permite a cualquiera (anon o autenticado) leer, insertar y actualizar cualquier sala.
-- IMPORTANTE: En producción, esto debe restringirse, pero para probar es necesario.
CREATE POLICY "Public Access Game Rooms" 
ON public.game_rooms 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- 4. Asegurar que la publicación de tiempo real (Realtime) esté activa
-- Esto es necesario para que .stream() funcione
ALTER PUBLICATION supabase_realtime ADD TABLE public.game_rooms;
