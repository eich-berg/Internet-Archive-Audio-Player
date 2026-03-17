import rss_reader.{type Track}
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html


pub fn root(tracks: List(Track)) -> Element(msg) {
  html.div([], [
    html.h1([], [
      text("♪♫•*¨*•.¸¸❤ Internet Archive Audio Player ❤¸¸.•*¨*•♫♪")
    ]),
    html.p([], [
      text("The design for this web app is based on the Building your first Gleam web app with Wisp and Lustre tutorial @ "),
      html.a(
        [
          attribute.href("https://gleaming.dev/articles/building-your-first-gleam-web-app/"),
          attribute.target("_blank"),
        ],
        [text("gleaming.dev")],
      ),
    ]),
    html.p(
      [attribute.id("trackcount")],
      [text("TRACKS FOUND: " <> int.to_string(list.length(tracks)))]
    ),
    html.h2([], [
      text("Individual audio files may take a few seconds to load. Try navigating back and forth between tracks if a file is not loading.")
    ]),
    html.div([attribute.id("playerbox")], [
      html.p([], [text("NOW PLAYING")]),
      html.span([attribute.id("nowplaying")], [
        text("[click a track below]")
      ]),
      html.div([attribute.class("audio-player")], [
        html.h2([], [text("Internet Archive Player")]),
        html.audio(
          [
            attribute.id("audioPlayer"),
            attribute.controls(True),
            attribute.preload("metadata"),
          ],
          [
            text("Your browser does not support the audio element.")
          ],
        ),
        html.div([attribute.id("controls")], [
          html.button([attribute.id("btn-prev")], [text("PREV")]),
          html.button([attribute.id("btn-playpause")], [text("PLAY / PAUSE")]),
          html.button([attribute.id("btn-next")], [text("NEXT")]),
          html.button([attribute.id("btn-shuffle")], [text("SHUFFLE")]),
        ]),
        html.div([attribute.id("trackcounter")], [
          text("track 0 of " <> int.to_string(list.length(tracks)))
        ]),
      ]),
    ]),
    html.div([attribute.id("tracklist")], [
      html.p([], [
        html.b([], [text("TRACK LISTING:")])
      ]),
      html.ul([],
        case tracks {
          [] -> [html.li([], [text("No tracks available.")])]
          _ -> tracks |> list.map(render_track)
        }
      ),
    ]),
    html.p([], [
      text("Powered by "),
      html.a(
        [
          attribute.href("https://archive.org"),
          attribute.target("_blank"),
        ],
        [text("❤¸¸.•*¨*•The Internet Archive•*¨*•.¸¸❤")],
      ),
    ]),
    player_script()
  ])
}

fn render_track(track: Track) -> Element(msg) {
  html.li([attribute.class("track-item")], [
    html.a(
      [
        attribute.href("#"),
        attribute.class("track"),
        attribute.attribute("data-url", track.url),
      ],
      [
        text(track.artist <> " — " <> track.title <> " (" <> track.album <> ")")
      ],
    )
  ])
}

fn player_script() -> Element(msg) {
  html.script([], "
document.addEventListener('DOMContentLoaded', () => {

  const player    = document.getElementById('audioPlayer');
  const nowplaying  = document.getElementById('nowplaying');
  const trackcounter = document.getElementById('trackcounter');
  const btnPrev   = document.getElementById('btn-prev');
  const btnPlay   = document.getElementById('btn-playpause');
  const btnNext   = document.getElementById('btn-next');
  const btnShuffle = document.getElementById('btn-shuffle');

  let tracks = Array.from(document.querySelectorAll('.track'));
  let currentIndex = -1;
  let shuffled = false;
  let shuffleOrder = [];

  function buildShuffleOrder() {
    shuffleOrder = tracks.map((_, i) => i);
    for (let i = shuffleOrder.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffleOrder[i], shuffleOrder[j]] = [shuffleOrder[j], shuffleOrder[i]];
    }
  }

  function playIndex(index) {
    if (index < 0 || index >= tracks.length) return;
    currentIndex = index;

    const trackEl = tracks[currentIndex];
    player.src = trackEl.dataset.url;
    player.play();
    nowplaying.textContent = trackEl.textContent;
    trackcounter.textContent = 'track ' + (currentIndex + 1) + ' of ' + tracks.length;

    document.querySelectorAll('.track').forEach(t => t.classList.remove('active'));
    trackEl.classList.add('active');
  }

  function nextIndex() {
    if (shuffled) {
      const pos = shuffleOrder.indexOf(currentIndex);
      return shuffleOrder[(pos + 1) % shuffleOrder.length];
    }
    return (currentIndex + 1) % tracks.length;
  }

  function prevIndex() {
    if (shuffled) {
      const pos = shuffleOrder.indexOf(currentIndex);
      return shuffleOrder[(pos - 1 + shuffleOrder.length) % shuffleOrder.length];
    }
    return (currentIndex - 1 + tracks.length) % tracks.length;
  }

  tracks.forEach((track, i) => {
    track.addEventListener('click', e => {
      e.preventDefault();
      playIndex(i);
    });
  });

  btnPlay.addEventListener('click', () => {
    if (currentIndex === -1) {
      playIndex(shuffled ? shuffleOrder[0] : 0);
    } else if (player.paused) {
      player.play();
    } else {
      player.pause();
    }
  });

  btnNext.addEventListener('click', () => {
    if (currentIndex === -1) {
      playIndex(shuffled ? shuffleOrder[0] : 0);
    } else {
      playIndex(nextIndex());
    }
  });

  btnPrev.addEventListener('click', () => {
    if (currentIndex === -1) {
      playIndex(shuffled ? shuffleOrder[shuffleOrder.length - 1] : tracks.length - 1);
    } else {
      playIndex(prevIndex());
    }
  });

  btnShuffle.addEventListener('click', () => {
    shuffled = !shuffled;
    if (shuffled) {
      buildShuffleOrder();
      btnShuffle.style.opacity = '1';
      btnShuffle.style.textDecoration = 'underline';
    } else {
      btnShuffle.style.opacity = '0.5';
      btnShuffle.style.textDecoration = 'none';
    }
  });

  player.addEventListener('ended', () => {
    playIndex(nextIndex());
  });

});
")
}