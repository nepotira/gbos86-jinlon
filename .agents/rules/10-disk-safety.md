# Disk and Partition Safety Rules

- Máquina: HP Elite c1030 (Jinlon), Zorin OS, SSD `/dev/nvme0n1` (119 GiB). A ESP e o Zorin NÃO podem ser alterados.
- Em `/dev/nvme0n1` a única escrita permitida é criar UMA partição no espaço NÃO ALOCADO (ETAPA 1B, Argon), com backup da tabela (`sfdisk -d` e `sgdisk --backup`) e meu "sim" sobre o comando exato. Proibido redimensionar, mover, apagar ou formatar partições existentes, e proibido mexer em `/boot/efi`, GRUB, `efibootmgr` e `initramfs`.
- Fora isso, a única escrita em disco bruto é o `dd` no pendrive (ETAPA 2, Argon), depois do meu "sim" sobre o dispositivo. Nunca no `nvme0n1` nem em disco com partição montada em `/` ou `/boot`.
- Não apague nada fora de `~/gbos-work`, `/mnt/gbwork` e arquivos criados pelo agente. Não reinicie sem avisar. Não use Ventoy.
- Não commite nem distribua imagens, bibliotecas, firmware ou qualquer arquivo da Google ou de terceiros.
