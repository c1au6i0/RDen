---
title: Il Re di Twitter? (PART II)
subtitle: Analisi dei tweets
author: C1au6i0_HH
date:  '2018-10-10'
# lastmod: "2019 July 12 10 02"
slug: re-di-twitter-ii
categories:
  - R
tags:
  - textmining
  - twitter
  - twitteR
keywords: []
description: ''
comment: yes
toc: yes
autoCollapseToc: no
contentCopyright: no
reward: no
mathjax: no
---

In questa seconda parte analizzeremo il contenuto dei tweets di Di Maio, Salvini e Martina e scopriremo quante volte e quando particolari parole sono state utilizzate dai 3 politici. Per finire andremo a vedere se alcune di queste parole sono associate ad un alto numero di like.

<!--more-->

# Premessa

Nella prima parte di prima serie di [posts] (https://muaydata.netlify.com/post/il-re-di-twitter-parte-i/) ci siamo calati nel ruolo di brillanti investigatori privati e muniti della nostra lente di ingrandimento informatica (*twitteR*) abbiamo analizzato l'uso da parte di Di Maio, Salvini e Martina del social media twitter. Nell'apparente casualità del comportamento umano, patterns e ordine emergono quando i dati vengono osservati e registrati sistematicamente e così siamo stati in grado di rilevare trend e differenze nell'uso di twitter da parte dei 3 politici italiani. In questa __seconda parte__ andremo ad analizzare il contenuto dei vari tweets utilizzando un pacchetto di *textmining* estremamente popolare in *R*: [*tidytext*](https://www.tidytextmining.com/). 

# Analisi

## Preparazione dati e tokenizzazione

La procedura per ottenere un dataframe/tibble dei tweets dei 3 politici (a cui assegneremo il nome di __twdat__) è spiegata in dettaglio nel mio primo post della serie e nella [guida di Michael Galarnyk](https://medium.com/@GalarnykMichael/accessing-data-from-Twitter-api-using-r-part1-b387a1c7d3e). 

Queste sono le librerie che ci serviranno per le nostre analisi.

```r
library("ggridges")
library("ggrepel")
library("lubridate")
library("RSQLite")
library("scales")
library("stringr")
library("tidytext")
library("tidyverse")
```

<!-- Database -->


Il primo processo necessario prima di qualunque analisi del testo è la *tokenizzazione*, ovvero l'estrazione di singole unità di testo con significato, nel nostro caso singole parole.
Il codice sottostante che è stato adattato da quello di [David Robinson](http://varianceexplained.org/r/trump-tweets/) serve a:

* tokenizzare il contenuto della colonna *text* del dataframe *twdat* attraverso il comando *unnest_tokens*.
* rimuove *stop words*, ossia parole come articoli e proposizioni prive di significato.
* rimuovere links, simboli e particelle come *https* o *rt*.


```r
reg <- "([^[:alpha:]\\d#@']|'(?![[:alpha:]\\d#@]))"
ita_stop_words <- get_stopwords(language = "it", source = "snowball")

twwords <- twdat %>%
  mutate(text = str_replace_all(text, "(http|https)://t.co/[A-Za-z\\d]+|&amp;", "")) %>% # remove links
  mutate(text = str_replace_all(text, "[[:punct:]]", " ")) %>% # removes punctualization
  unnest_tokens(word, text, token = "regex", pattern = reg) %>% 
  filter(!word %in% ita_stop_words$word,
         str_detect(word, "[[:alpha:]]"),
         nchar(word) > 1,
         !word %in% c("rt", "http", "https", "gt") #remove other not meanigful words
         )
```

Il risultato viene assegnato ad un dataframe/tibble in cui le informazioni originali di *twdat* vengono conservate ma la colonna che contiene tweets (chiamata *text*) viene sostituita con una chiamata *word* in cui ogni osservazione è una singola parola (*one token per row"). Abbiamo a questo punto un dataframe/tibble con cui possiamo lavorare.

## Frequenza delle parole

Come prima cosa andiamo a vedere quali sono le parole più usate dai 3 politici. Per ogni politico calcoliamo la percentuale di tweets che contiene le varie parole, andiamo poi a selezionare le prime 20 parole e le assegnamo ad un nuovo database/tibble (*f_twwords*).


```r
# filtered tweets with percent times a word has been used
f_twwords <- twwords %>%
  group_by(screenName) %>% 
  mutate(tot = length(unique(id))) %>% # here calculate the tot number of tweets 
  group_by(word, screenName) %>% 
  summarize(n = length(unique(id)), perc = length(unique(id))/first(tot)) %>% 
  group_by(screenName) %>% 
  do(top_n(., 20, perc)) # discovered top_n thanks to We are R-Ladies
```

Disegneremo il grafico con  *ggplot* ma prima sarà necessario ordinare per ogni politico i livelli della colonna *word* a seconda di quella delle percentuali *perc* (grazie [MrFlick](https://stackoverflow.com/questions/48179726/ordering-factors-in-each-facet-of-ggplot-by-y-axis-value))


```r
new_order <-
  f_twwords %>%
  do(data_frame(al=levels(reorder(interaction(.$screenName, .$word, drop=TRUE), .$perc)))) %>%
  pull(al)
```

```
## Warning: `data_frame()` is deprecated, use `tibble()`.
## This warning is displayed once per session.
```

Creiamo a questo punto il grafico in cui le parole usate da ogni politico saranno nell'asse delle Y e la loro frequenza in quello delle X.


```r
f_twwords %>% # frequency tweet words
  mutate(al = factor(interaction(screenName, word), levels = new_order)) %>%
  ggplot(aes(x = perc, y = al, col = screenName)) +
    geom_point() +
    facet_grid(screenName~., scales = 'free_y') +
    scale_y_discrete(breaks = new_order, labels = gsub("^.*\\.", "", new_order)) + # this is to sort the y-axis breaks by the order created in previous chunck
    scale_x_continuous(labels = percent) +
    scale_color_manual(values = c("#FFC125","#00BA38","#F8766D")) +
    labs(y = NULL, x = "Percent tweets", caption ="fig.1") +
    theme(plot.title = element_text(hjust = 0.5),
          legend.position = "none")
```

<img src="/post/2018-10-09-re-di-twitter-ii_files/figure-html/fig1_most_used_words-1.png" width="768" style="display: block; margin: auto;" />

__Per Salvini e Martina la parola più usata è il proprio nome/screenname__, mentre per __Di Maio è il partito__ "m5s". __Salvini menziona il suo nome in circa 1 tweets ogni 3, Martina e Di Maio menzionano nome e partito in 1 tweet ogni 10 , rispettivamente__.

In termini di frequenza d'uso, __il primo riferimento diretto Di Maio a se stesso (*luigidimaio*) è all'undicesimo posto__, dopo 6 riferimenti al partito e al suo fondatore (fig.1). __È inoltre più probabile trovare le parole _renzi_ o _pd_ in un tweet di Di Maio che la parola *luigidimaio*! È più probabile trovare la parola *pd* in un tweet di Di Maio che im uno di Martina*__

Sono tuttavia necessarie alcune precisazioni per meglio interpretare questi risultati. Il riferimento a se stessi dei vari politici è di *natura* diversa. Per Salvini il riferimento al proprio nome è nell'ambito dell'hastag *#salvini* mentre per Martina e Di Maio in retweet in cui vengono citati (*luididimaio*, *maumartina*).
  
I temi/slogan (*agricoltura, primagliitaliani*) e espressioni (*amici*) cari ai 3 politici emergono tra le 20 parole più usate, con alcuni elementi chiaramente in comune. Quali sono questi temi condivisi? Andiamo a vedere con alcuni semplici comandi per intersecare le tre liste di parole.
  

```r
# Split dataframe, select words  column and create a list. Intersect list
words_m <- map(split.data.frame(f_twwords , f_twwords$screenName),
              function(x) {ungroup(x) %>% select(word)})
knitr::kable(Reduce(intersect, words_m), caption = "tab.1")
```



|word   |
|:------|
|italia |
|oggi   |
|pd     |

I temi in comune tra i 3 politici sono la patria (*italia*), il presente (*oggi*) e il...__partito democratico __(*pd*). I sostenitori del m5s sono stati spesso bersaglio di satira per l'uso considerato eccessivo di riferimenti e comparazioni con il PD [link](https://www.lercio.it/maturita-al-posto-della-soluzione-scrive-e-allora-il-pd-e-passa-la-prova-di-matematica/)

In fine ricorriamo ad una diverso strumento, il *wordcloud* per rappresentare in maniera più accattivante i dati della figura precedente. Ho usato la libreria *ggrepel* per evitare che le parole si sovrapponessero.

```r
f_twwords %>%
    ggplot(aes(x = 1, y = 1, size = perc, label = word, col = screenName)) +
      geom_text_repel(segment.size = NA, force = 100) +
      scale_size(range = c(2, 15), guide = FALSE) +
      scale_y_continuous(breaks = NULL) +
      scale_x_continuous(breaks = NULL) +
      scale_color_manual(values = c("#FFC125","#00BA38","#F8766D")) +
      labs(x = '', y = '', caption="fig.2") +
      theme(legend.position = "none", panel.background = element_rect(fill = NA)) +
      facet_grid(screenName~., scales = 'free_y', labeller = labeller(screenName = NULL))
```

<img src="/post/2018-10-09-re-di-twitter-ii_files/figure-html/fig.2_worcloud-1.png" width="576" style="display: block; margin: auto;" />

Nella fig.2, le parole più usate hanno una dimensione maggiore.

## Andamento 

Le analisi svolte finora hanno evidenziato una serie di parole che con più probabilità di altre si trovano nei tweets dei tre politici. La parola *pd* è una di queste, non soltanto per Martina ma anche per Salvini e Di Maio. Una così alta attenzione per il PD da parte di forze politiche ormai al governo mi ha sorpreso. Tuttavia un importante fattore era stato finora ignorato: __il tempo!__


Nelle analisi precedenti abbiamo infatti accorpando insieme gli ultimi ≈3200 tweets di ogni politico, andando perciò a *riassumere*  periodi di attività anche molti lunghi, e nel caso Di Maio, un periodo di circa 4 anni.

Andiamo perciò a vedere come l'uso di alcune delle parole più frequenti è cambiato nel tempo. Iniziamo con creare la lista delle 7 parole (*top_w*) più usate da ogni politico come mostrato in fig.1. Per motivi pratici salveremo queste informazioni in un unica lista (invece che un dataframe) in cui ogni elemento sara nel formato nomepolitico_parola.


```r
top_w <- f_twwords %>%   
  group_by(screenName) %>% 
  do(top_n(., 7, perc)) %>% 
  unite(screenName_word, screenName, word, remove = FALSE) %>% 
  ungroup() %>% 
  select(screenName_word) %>% 
  unlist()
```
A questo punto calcoliamo per ogni mese il totale dei tweets, il numero di tweets che contengono ogni diversa parola, e relativa percentuale. Uniamo anche per questo dataframe/tibble la colonna con il nome del politico e quella delle parole.


```r
fm_twwords <- twwords %>%  # frequencymonth_tweetswords
  mutate(month_r = floor_date(created, "month") ) %>%
  group_by(screenName, month_r) %>% 
  mutate(tot = length(unique(id))) %>% # here calculate the tot number of tweets 
  group_by(word, screenName, month_r) %>% 
  summarize(n = length(unique(id)), perc = length(unique(id))/first(tot), tot = first(tot)) %>% 
  unite(screenName_word, screenName, word, remove = FALSE) %>%  #
  arrange(screenName, desc(perc))
```

Mi concentrerò sui dati di Di Maio che sono quelli in cui un analisi temporale rivela informazioni più interessanti. Il codice sottostante serve a filtrare il dataframe/tibble con le 7 parole più usate (*top_w*), a riordinarle per il grafico, e a codificarle in modo da creare delle appropriate *facet* nel grafico successivo.


```r
fm_twwords_lm <- fm_twwords %>% 
  filter(screenName == "luigidimaio", screenName_word %in% top_w)

wd_lm <- c("beppe",
           "stelle",
           "m5s",
           "governo", 
           "oggi",
           "pd",
           "renzi"
           ) 
fm_twwords_lm$word <- factor(fm_twwords_lm$word, levels = wd_lm)
letters_lm <- LETTERS [c(1, 1, 1, 2, 2, 3, 3)]

newnames <- setNames(letters_lm, wd_lm)

fm_twwords_lm[, "facet_w"] <- newnames[fm_twwords_lm$word]
```

Andiamo finalmente a rappresentare graficamente le 7 parole più usate da Di Maio in funzione del tempo, per gli ultimi 3 anni.


```r
  fm_twwords_lm  %>% 
  filter(month_r >= ymd("2014-07-01"), month_r <=  ymd("2018-07-01")) %>% 
  ggplot(aes(x = month_r, y = perc,  col = word)) +
  geom_vline(xintercept = ymd("2018-06-01", tz = "UTC"), lty = 5) +
  geom_point(size = 2) +
  geom_line() +
  scale_x_datetime(labels = date_format("%Y %b"), date_breaks= "4 months") +
  geom_text(aes(y = 0.4, x = ymd("2018-01-01", tz = "UTC"), label = "before"), col = "black", size = 3) +
  geom_text(aes(y = 0.4, x = ymd("2018-07-01", tz = "UTC"), label = "after"), col = "black", size = 3, angle = 45, hjust = 0) +
  scale_y_continuous(labels = percent) +
  scale_color_brewer(type = "qual", palette = 2) +
  facet_grid(facet_w ~ .) +
  theme(plot.subtitle = element_text(vjust = 1),
    plot.caption = element_text(vjust = 1),
    axis.text.x = element_text(vjust = 0.25, angle = 45)
    ) +
  labs(x = NULL, y = NULL, col = NULL, group = NULL, title = "Di Maio - Percent tweets", caption= "fig.3") +
  theme(plot.title = element_text(hjust = 0.5)) 
```

<img src="/post/2018-10-09-re-di-twitter-ii_files/figure-html/fig.3_timeline_dimaioa-1.png" width="672" style="display: block; margin: auto;" />

Le 3 parole relative al movimento e al suo fondatore (fig.3 panello A) sono state usate da Di Maio costantemente ma con frequenza variabile negli ultimi anni. È tuttavia negli ultimi mesi (da Marzo a Luglio 2018) che il loro uso è andato quasi scomparendo. Questa diminuzione si è verificata nel concitato periodo di consultazioni con il quirinale e formazione del governo (Febbraio-Giugno), mesi in cui la parola *governo* è usata ogni 2-5 tweets (fig.3 panello B). 
E le parole relative al PD? __I riferimenti da parte di Di Maio al attuale partito di opposizione (parola *pd*) e al suo precedente segretario (parola *renzi*)__ se pure a tratti molto frequenti tra il 2014-2017, __scompaiono completamente nel periodo in cui il movimento a 5 stelle diventa partito di maggioranza__ (fig.3 pannello C, linea tratteggiata indica l'insediamento del governo). 
Anche riferimenti al *governo* e le la parola *stelle* diminuiscono di frequenza o scompaiono dai tweets di Di Maio in Giugno e Luglio.
Di che cosa parla allora negli Di Maio in questi ultimi mesi presi in esame?
Andiamo a vedere le 2 parole utilizzate in diversi tweets per i mesi di Giugolo e Luglio.


```r
fm_twwords  %>% 
  filter(screenName == "luigidimaio") %>% 
  filter(month_r >= ymd("2018-06-01"), month_r <= ymd("2018-07-01")) %>% 
  mutate(perc = perc * 100) %>% 
  group_by(month_r) %>% 
  do(top_n(., 3, perc)) %>% 
  arrange(desc(month_r)) %>% 
  select(word, month_r, n, tot, perc) %>% 
  knitr::kable(caption = "tab.2")
```



|word            |month_r    |  n| tot|     perc|
|:---------------|:----------|--:|---:|--------:|
|byebyevitalizi  |2018-07-01 | 22|  44| 50.00000|
|mov5stelle      |2018-07-01 | 11|  44| 25.00000|
|oggi            |2018-07-01 |  7|  44| 15.90909|
|giuseppeconteit |2018-06-01 |  5|  16| 31.25000|
|presidente      |2018-06-01 |  3|  16| 18.75000|
|domani          |2018-06-01 |  2|  16| 12.50000|
|ex              |2018-06-01 |  2|  16| 12.50000|
|finalmente      |2018-06-01 |  2|  16| 12.50000|
|italy           |2018-06-01 |  2|  16| 12.50000|
|lavoro          |2018-06-01 |  2|  16| 12.50000|
|oggi            |2018-06-01 |  2|  16| 12.50000|
|parlamentari    |2018-06-01 |  2|  16| 12.50000|
|realdonaldtrump |2018-06-01 |  2|  16| 12.50000|

I riferimenti di Di Maio al movimento restano alti anche se attraverso parole (*mov5stelle*) differenti da quelle indicate in fig.3 (ma già individuate tra le 20 parole più utilizzate da Di Maio). Inoltre, __(ri/)affiorano con alta frequenza menzioni al presidente del consiglio (*giuseppeconte.it*, *presidente*) e all'opera del governo (*byebyevitalizi*). 
  Pertanto, __nei mesi di Giugno e Luglio, Di Maio continua a parlare del movimento  e dell'opera del governo ma usando con più frequenza parole differenti da quelle usate precedentemente__. Inoltre in Giugno, __i riferimente al fondatore (*beppe*), sembrano essere stati rimpiazzati con quelli diretti al presidente del consiglio__.

## Popolarità e parole

Il processo di *tokenizzazione*  iniziale  ci ha permesso di associare ad ogni parola un numero di likes (quello del tweet in cui è stata usata) che rappresenta un ottimo indice di popolarità/approvazione da parte della base dei followers. __Andiamo quindi a vedere quali sono le parole che sono più apprezzate dai relativi followers dei 3 politici__.

Iniziamo calcolando per ogni politico,la media dei likes per parola/tweet e selezionando le 10 parole con maggiori likes.

```r
fav_twwords_all <- twwords %>%  # favmonth_tweetswords
  group_by(screenName) %>% 
  mutate(tot = length(unique(id))) %>% # here calculate the tot number of 
  group_by(word, screenName) %>% 
  summarize(n = length(unique(id)), fav = sum(favoriteCount)/n) %>% 
  group_by(screenName)

fav_twwords <- fav_twwords_all %>% 
  do(top_n(., 10, fav)) 
```

Ordiniamo i livelli del fattore *word* per poter conseguentemente riorganizzare i livelli nell'asse delle x del prossimo grafico in ordine di media di likes.


```r
new_order <-
  fav_twwords %>%
  do(data_frame(al=levels(reorder(interaction(.$screenName, .$word, drop=TRUE), .$fav)))) %>%
  pull(al)
```

Per ultimo creiamo il grafico a barre del numero di like per tweet delle 10 parole che sono state più apprezzate. Attraverso *geom_text* possiamo indichiamo all'interno di ogni barra il numero di tweets che contiene la parola sotto esame.

```r
fav_twwords %>% 
  mutate(al = factor(interaction(screenName, word), levels = new_order)) %>% 
  ggplot(aes(x = al, y = fav, fill = screenName)) +
  geom_col() +
  scale_fill_manual(values = c("#FFC125","#00BA38","#F8766D")) +
  geom_text(aes(y = 0, label = n), vjust = -0.5, size = 3) +
  facet_grid(.~ screenName, scales = 'free_x') + 
  scale_x_discrete(breaks = new_order, labels = gsub("^.*\\.", "", new_order)) +
  labs(y = "Number of likes / tweet", x = " ", caption ="fig.4") +
  theme(plot.subtitle = element_text(vjust = 1), 
    plot.caption = element_text(vjust = 1), 
    axis.text.x = element_text(vjust = 1, 
                               hjust = 1,
                               angle = 45),
    legend.position = "none")
```

<img src="/post/2018-10-09-re-di-twitter-ii_files/figure-html/fig.4_like_word-1.png" width="768" style="display: block; margin: auto;" />

Il primo dato che balza agli occhi dalla fig.4 è che __le prime 10 parole più usate da Salvini hanno totalizzato un numero molto più alto di likes rispetto quelle di Di Maio e Martina__.
Inoltre, le parole che hanno ricevuto più likes sono state utilizzate __soltanto 1 o 2 volte dai vari politici__.  Perché? 
Andiamo a rileggere i [10 tweets più popolari dei tre politici] (https://muaydata.netlify.com/post/il-re-di-twitter-parte-i/#&gid=1&pid=7). La quasi totalità delle parole con più like si annidata tra quei tweet. Si tratta di parole "discriminanti" che identificano in maniera univoca il tweet perché non comunemente usate in altri tweets (con bassi likes). Esemplificativo è il caso delle parole *gove*, *que* e *trat* che sono parole tagliate (governo, queste, tratta) da *twitteR* per raggiunto limite di caratteri e perciò si trovano unicamente in questi tweets.

Per la stessa ragione, alcune parole se pure presenti nei tweets più popolari non sono tra quelle con maggiori like per tweets. Per di Maio una di queste è __la parola *vitalizi* che viene menzionata 2 volte tra i [dieci tweets con più likes](https://muaydata.netlify.com/post/il-re-di-twitter-parte-i/#&gid=1&pid=7)__. Si tratta di una parola che è stata usata da Di Maio per un totale di 28 volte negli ultimi anni.

Nella figura sottostante ogni punto rappresenta un tweet che contiene la parola *vitalizi*, collocato più in alto a seconda del numero di likes ricevuti.


```r
vital <- fav_twwords_all %>% 
  filter(screenName == "luigidimaio", word == "vitalizi") 

twwords %>%
  filter(screenName == "luigidimaio", word == "vitalizi") %>% 
  ggplot(aes(screenName, favoriteCount, col = screenName)) +
  geom_jitter(size = 5, colour = "#FFC125", width = .4) +
  geom_hline(yintercept = vital$fav, show.legend = FALSE) + 
  scale_x_discrete(labels = "word: vitalizi") +
  geom_label(aes(y = vital$fav, label = "mean"), colour = "black") +
  labs(y = "Number of likes", x = "", caption ="fig.5") +
  theme(legend.position = "none",
        axis.text.x = element_text(size = 14))
```

<img src="/post/2018-10-09-re-di-twitter-ii_files/figure-html/fig.5_vitalizi-1.png" width="384" style="display: block; margin: auto;" />

Anche se in quelle 2 occasioni il numero di like ricevuti è stato estremamente alto, la presenza di numerosi tweets con pochi like ha spostato la media di like per tweet verso il basso (fig.5).

È pertanto evidente che __nessuna singola parola può essere usata ripetutamente per garantire (o essere un buon predittore del) sucesso dei tweets dei 3 politici__. Il significato dei tweet si annida tra le combinazioni di parole e in temi che possono essere espressi in maniera differente. In questa circostanza e in queste condizioni risulta perciò più informativo l'analisi dell'[intero tweet](https://muaydata.netlify.com/post/il-re-di-twitter-parte-i/#&gid=1&pid=7) piuttosto che delle singole parole.

Analisi più approfondite come quelle relative alla combinazioni di parole e *sentiment analysis* possono essere utilizzate per visionare e catturare temi o "significati" generali.
Ma vista mancanza di strumenti adeguati per la lingua italiana, ho deciso di completare qui la mia analisi di questo dataset!

# Conclusioni

* La parola che con più frequenza compare nei tweet di Salvini e Martina è il loro stesso nome, mentre in quelli di Di Maio è il partito (*m5s*) (fig.1, fig.2). 
* Alcune parole sono usate con alta frequenza da tutti e tre i politici (tab.1). Tra le top 3, compare la parola *Italia* e quella __*pd*__.
* È più facile trovare un riferimento al PD e a Renzi in un tweet di Di Maio che in uno di Martina. Le parole *pd* e *renzi* compaiono con maggiore frequenza di quella *luigidimaio* nei tweet di Di Maio (fig.1).
* I riferimenti di Di Maio a PD e Renzi scompaiono completamente a partire dal periodo delle consultazioni e formazione del governo (fig.3, tab.2).
* Nessuna singola parola è sufficiente a predire la possibile popolarità (likes) dei tweet dei 3 politici tra i rispettivi followers.

Analisi più approfondite come quelle relative alla combinazioni di parole e *sentiment analysis* possono essere utilizzate per visionare e catturare temi o "significati" generali e potrebbero permettere predizioni della popolarità dei vari tweets. Tuttavia, vista la mancanza di strumenti adeguati per la lingua italiana, ho deciso di completare qui la mia analisi di questo dataset! I prossimi post saranno in Inglese e decisamente più brevi! 
