# Mask-Detector Deep-Learning IOS App

![Logo](https://github.com/SwiftJimmy/Hausarbeit_Wissensmanagement_Deep_Learning/blob/master/9.%20App-Entwicklung/logo.png)

## Einleitung

Seit Anfang 2020 stehen wir als Menschheit vor der Herausforderung die globale Verbreitung des COVID-19 Virus einzudämmen. Die bisher vorliegenden Informationen zur Epidemiologie des Virus zeigen, dass Übertragungen insbesondere bei engem ungeschütztem Kontakt zwischen Menschen vorkommen. Nach derzeitigem Kenntnisstand des Robert-Koch-Instituts (RKI)  erfolgt die Übertragung vor allem über respiratorische Sekrete, in erster Linie Tröpfchen, die z.B. beim Husten, Niesen, oder lautem Sprechen freigesetzt werden. Aus diesem Grund empfiehlt das RKI das Tragen eines mehrlagigen medizinischen Mund-Nasen-Schutzes, um zum einen die Freisetzung erregerhaltiger Tröpfchen aus dem eigenen Nasen-Rachen-Raum zu behindern und zum anderen die Aufnahme von Tröpfchen oder Spritzern aus dem Nasen-Rachen-Raum des Gegenübers zu verhindern. 

Aus diesem Grund besteht unter anderem in Berlin die Pflicht zum Tragen des Mund-Nasen-Schutzes in allen öffentlichen Einrichtungen sowie im öffentlichen Nahverkehr. Um zu überprüfen, ob die angeordneten Bestimmungen von der Bevölkerung angenommen werden, ist unsere Idee eine automatisierte statistische Erhebung durchzuführen, die auf Grundlage von Deep-Learning erfasst, ob der Mund-Nasen-Schutz regelkonform getragen wird. 

Ein Ansatz dafür könnte perspektivisch die Installation von IOT Geräten an öffentlichen Plätzen sein, welche mithilfe eines vorab trainierten neuronalen Netzes live das Tragen von Masken durch Kameraaufnahmen ermitteln. Die dabei erfassten Daten, können im Anschluss für eine statistische Auswertung genutzt werden. 

Um dieser Idee einen Schritt näher zu kommen, möchten wir in dieser Ausarbeitung ein Object-Detection-Modell trainieren, welches auf Bildern Gesichter erkennt, die den Mund-Nasen-Schutz tragen, nicht tragen oder falsch tragen. Dieses Modell soll im Anschluss prototypisch in eine IOS App eingebunden werden, um es im live Einsatz testen zu können. Dabei sollen in der App bereits eine Zählung sowie statistische Auswertung der erkannten Kategorien erfolgen. 

Grundlegend ist das Modell und die dazugehörige Applikation nicht für den kommerziellen Gebrauch vorgesehen. Die Zielgruppe könnten Institute wie das RKI sein, welche eine Veränderung der Reproduktionszahl mit dieser statistischen Auswertung in Zusammenhang setzen könnte. Auch Anwendungsmöglichkeiten im Bereich der Soziologie sind denkbar, wobei ermittelt werden kann, wie eine Bevölkerung mit dem Umstand der Pandemie umgeht. Weiterhin könnten staatliche Einrichtungen die Anwendung nutzen, um zu erkennen, wie gut die angeordneten Bestimmungen von der Bevölkerung befolgt werden. 

Um eine qualitativ hochwertige statistische Aussage treffen zu können, ist eine hohe Genauigkeitsrate des Modells wichtig. Zudem ist es entscheidend, dass das Modell schnell reagiert, da es in dem perspektivischen IOT Projekt Live-Zählungen durchführen soll.  Daher streben wir eine Modellgenauigkeit von mindestens 95% sowie eine für Live-Erkennung geeignete hohe Geschwindigkeit an. 

## Dokumentation
Die Herangehensweise der Ausarbeitung des Projektes wird in der Dokuemntation (Doku.pdf) beschrieben. 
Die Ordnerstruktur in diesem Repository entspricht den Kapiteln der Dokumentation. 

## Installation der IOS App
Die IOS Applikation befindet sich im Ordner 9. App-Entwicklung -> Mask-Detector IOS App. Um diese auf dem eigenen Gerät zu installieren wird ein Apple Developer Account sowie Xcode benötigt. Sobald das Projekt in Xcode geöffnet wurde muss ggf der eigene Developer-Acount hinterlegt werden. 
