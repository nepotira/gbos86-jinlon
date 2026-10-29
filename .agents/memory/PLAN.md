# Execution Plan (PLAN)

PARTE 2: EXECUÇÃO (a ETAPA 0 já foi feita)

Regras completas: ~/.gemini/GEMINI.md e .agents/rules/ do projeto. Regra de ouro, válida mesmo se esses arquivos não carregarem: no SSD só criar UMA partição no espaço não alocado (ETAPA 1B), o único dd é no pendrive confirmado por mim, nada fora de ~/gbos-work e /mnt/gbwork é apagado, e nenhuma senha é gravada.

## CONTEXTO
HP Elite c1030 (Jinlon, Comet Lake) com Zorin OS. SSD /dev/nvme0n1 (119 GiB) com cerca de 45 GiB não alocados. Objetivo: construir a imagem do gbOS86 (https://gbos86.com/docs/install, https://github.com/linuxkid473/gbos-x86), gravá-la em um pendrive para teste live e coletar dados de áudio e hardware.

## ETAPA 1: FLASH (reconhecimento e build)
1. Salve em .agents/memory/baseline/: lsblk -f, sudo parted /dev/nvme0n1 unit MiB print free, df -h, free -h, uname -r, /etc/os-release. Preencha ENV.md.
2. Confirme >= 40 GiB não alocados. Meça o espaço livre do filesystem do HOME. Se >= 40 GiB: BUILD_DIR=~/gbos-work/build. Senão, escreva "BLOQUEADO: precisa de GBWORK" no HANDOFF com início e fim do trecho livre em MiB e PARE (próximo: Argon, ETAPA 1B). Se o HANDOFF disser que a GBWORK está pronta, use /mnt/gbwork e comece pelo item 3.
3. Ferramentas: git, python3, curl, docker (no Zorin use docker.io), meu usuário no grupo docker (use "sg docker -c" ou sudo). Se o BUILD_DIR estiver na GBWORK, ponha o data-root do Docker em /mnt/gbwork/docker e anote como reverter.
4. Dados do notebook, só leitura, em ~/jinlon-pack (compactar em ~/jinlon-pack.tar.gz): amixer -c 0 contents, aplay -l, arecord -l, /proc/asound/cards, /proc/asound/card0/, lsmod filtrado por snd|sof|rt5682|max98357, ls -lR /lib/firmware/intel/sof*, /usr/share/alsa/ucm2/conf.d/sof-rt5682/, lspci -nnk, lsusb, /proc/bus/input/devices, ls /sys/class/backlight, rfkill list, sudo dmesg. Se o som não funcionar neste Zorin, só registre.
5. Clone em BUILD_DIR/gbos-x86, leia README e build.sh, rode ./build.sh --dry-run (mostre no máximo 30 linhas). Se perguntar o tipo de imagem, me mostre as opções e pergunte. Rode ./build.sh com log em arquivo (tmux ou nohup; baixa cerca de 8 GB) e consulte o log no máximo a cada ~5 min. Se falhar, diagnostique pelo log.
6. Registre no HANDOFF: caminho da imagem dist/gbOS86-*.img, bytes e sha256. Próximo: Argon, ETAPA 2.

## ETAPA 1B: ARGON (só se BLOQUEADO)
1. Releia o espaço livre (parted unit MiB print free).
2. Backup: sudo sfdisk -d /dev/nvme0n1 > .agents/memory/nvme0n1-gpt-backup.txt e sudo sgdisk --backup=<caminho>.bin /dev/nvme0n1.
3. Mostre o comando exato (parted, início e fim em MiB alinhados a 1 MiB, dentro do trecho livre) que cria UMA partição de 42 GiB no começo do trecho e espere meu "sim".
4. Execute, partprobe, identifique a partição nova (número que não existia no baseline) e formate SOMENTE ela: mkfs.ext4 -L GBWORK. Sem fstab. Monte em /mnt/gbwork, dê posse ao meu usuário, confirme >= 40 GiB livres.
5. Compare lsblk com o baseline: as partições anteriores devem estar idênticas; senão pare.
6. HANDOFF: "GBWORK pronta. Próximo: Flash, retomar a ETAPA 1 pelo item 3."

## ETAPA 2: ARGON (gravar o pendrive)
1. Confirme que a imagem existe e o sha256 confere.
2. lsblk -o NAME,SIZE,RM,TRAN,MODEL,SERIAL,MOUNTPOINTS; exclua o nvme0n1 e qualquer disco com partição montada em / ou /boot; mostre o candidato (modelo e bytes) e espere meu "sim"; se a imagem for maior que o pendrive, pare.
3. Desmonte e grave: sudo dd if=<imagem> of=/dev/<dispositivo> bs=4M status=progress conv=fsync; sync; partprobe.
4. Verifique: sudo cmp -n <bytes da imagem> <imagem> /dev/<dispositivo>.
5. HANDOFF. Próximo: Flash, ETAPA 3.

## ETAPA 3: FLASH (preparar o pendrive)
1. Monte a partição FAT de rótulo GBOS, guarde cópia do gbos/gbos.cfg em .agents/memory/ e defina MODE=live e DENSITY=180 sem mexer em outras chaves (formato em https://gbos86.com/docs/configuration); mostre o diff.
2. Procure em gbos/modules e gbos/firmware por rt5682, max98357, sof-cml e sof-cml-rt5682-max98357a; registre o que existe e o que falta (até 15 linhas).
3. Se faltarem sof-cml.ri (intel/sof/community/) ou a topologia sof-cml-rt5682-max98357a.tplg (intel/sof-tplg/): procure no meu sistema (inclusive .zst); se não houver, baixe a release oficial de https://github.com/thesofproject/sof-bin e use a versão que o kernel espera (no meu notebook funcionou firmware ABI 3:22). Respeite a estrutura de pastas existente. Não modifique módulos; só liste os que faltarem.
4. sync, desmonte e me avise. Próximo: Argon, ETAPA 4.

## ETAPA 4: ARGON (revisão final e publicação)
1. Compare o lsblk atual com o baseline (a única mudança permitida é a GBWORK).
2. Confirme no pendrive MODE=live e o cmp da ETAPA 2.
3. Rode scripts/scan-sensitive.sh em toda a árvore; mostre git status e a lista de arquivos; espere meu "sim".
4. Confirme gh auth status (se não estiver logado, pare: eu rodo "gh auth login"). Publique: gh repo create gbos86-jinlon --public --source . --remote origin --push, com descrição e tópicos; crie os rótulos; abra duas issues ("Test: live USB boot on Jinlon" e "Audio: sof-rt5682 + max98357a"); crie a tag anotada v0.1.0 e o release ("Initial documentation skeleton, nothing tested yet").
5. Relatório final (até 15 linhas): imagem e sha256, estado do pendrive, o que falta no áudio, caminho do jinlon-pack, link do repositório, como reverter o Docker (se mudou).

## ETAPA 5: FLASH (repetível, depois de CADA teste meu)
Quando eu trouxer os resultados do teste, rode o workflow /test-report. Nunca registre como funcionando algo que eu não confirmei.

## PARTE 3: INSTALAÇÃO ISOLADA NO SSD

SEÇÃO PARA 10-disk-safety.md:
Exceção da ETAPA 7 (instalação isolada, Argon): pode criar até 3 partições (GBOSSYS, GBOS_META opcional, GBOS_DATA) exclusivamente dentro do trecho não alocado, formatar apenas essas, e copiar arquivos do pendrive para elas e para /EFI/gbos/ da ESP. Exige: backup da tabela (sfdisk -d e sgdisk --backup), backup do conteúdo da ESP, efibootmgr -v salvo (leitura), dry-run mostrado e meu "sim". Continua proibido: alterar, redimensionar, mover ou formatar partições existentes, apagar arquivos existentes da ESP, mexer em initramfs. Alterar o GRUB ou criar entrada UEFI só pelo método que EU escolher.

## ETAPA 6: FLASH (pesquisa e rascunho; nada é executado no disco)
1. Leia https://gbos86.com/docs/how-it-works, /docs/install e /faq, e os tópicos https://gbos86.com/forum/t/19 e /forum/t/17, e qualquer outro tópico sobre dual-boot ou instalação em partição. Leia também o instalador no repositório linuxkid473/gbos-x86 (procure por GBOSSYS, GBOS_DATA, install, efibootmgr). Registre em docs/decisions/0002-isolated-install.md: o que o instalador oficial faz (partições, rótulos, sistemas de arquivos, arquivos copiados e onde, entrada de boot, como o stage0 encontra as partições no boot) e quais modos existem (live, instalar no NVMe, persistente em USB etc.).
2. Leia os repositórios dos guias da comunidade e liste os patches necessários (por exemplo, o hook.sh que recusa NVMe fora do instalador). NÃO execute nada deles. Aponte números de partição fixos ou comandos perigosos.
3. Somente leitura: salve em .agents/memory/ a saída de sudo efibootmgr -v, lsblk -f, parted unit MiB print free, df -h /boot/efi, ls -R /boot/efi/EFI (resumo) e qual bootloader o Zorin usa.
4. Escreva docs/INSTALL-ISOLATED.md (rascunho) com: layout proposto dentro do trecho livre (GBOSSYS FAT32 de cerca de 8 GiB, GBOS_DATA ext4 com o resto, e META se o instalador exigir); duas opções de boot (A: entrada pelo menu do firmware ou arquivo EFI direto, sem mexer no GRUB; B: entrada em /etc/grub.d/40_custom, reversível); passos; rollback completo. Recomende uma opção e explique em 5 linhas.
5. Escreva scripts/install-to-partition.sh: dry-run por padrão, --apply só com confirmação interativa; recusa operar fora do trecho livre; formata só partições novas (número que não existia no baseline); copia só o necessário; confere hashes; nunca usa wipefs nem sgdisk --zap-all; nunca toca em partições existentes. Rode shellcheck e o dry-run (o dry-run NÃO escreve nada).
6. Auto-rotação (somente leitura): ls /sys/bus/iio/devices; nome de cada dispositivo iio; lsmod | grep -E "cros_ec|iio"; dmesg | grep -iE "cros_ec|accel|iio|sensor"; veja se os módulos cros_ec_sensors ou equivalentes existem em gbos/modules no pendrive e o que o logcat diz. Registre os achados na issue #4 e em docs/AUDIO.md ou docs/HARDWARE.md.
7. Faça commit em branch feat/isolated-install, abra o PR e NÃO faça merge. HANDOFF: apresente as duas opções de boot e a sua recomendação, e peça minha escolha. Próximo: Argon, ETAPA 7.

## ETAPA 7: ARGON (revisão e execução)
1. Releia o script linha por linha contra a regra de segurança. Entregue um checklist: toca só no trecho livre? mkpart com limites explícitos? mkfs só nas partições novas? nada de wipefs ou zap? escreve na ESP só em EFI/gbos/? Se algo falhar, corrija ou pare.
2. Faça os backups (GPT em sfdisk e sgdisk, cópia da ESP com rsync, efibootmgr -v). Rode o dry-run e me mostre o plano exato (comandos, início e fim em MiB).
3. Espere meu "sim". Execute com --apply. Confira: lsblk igual ao baseline nas partições antigas, fsck nas novas, sha256 dos arquivos copiados batendo com o pendrive.
4. Configure o boot pelo método que eu escolhi. Não reinicie. Me diga como dar boot e como desfazer.
5. HANDOFF. Próximo: Flash, ETAPA 8.

## ETAPA 8: FLASH (depois que eu testar o boot do SSD)
Rode /test-report, atualize INSTALL-ISOLATED.md e os READMEs, faça merge do PR e rode /release (versão MINOR).
