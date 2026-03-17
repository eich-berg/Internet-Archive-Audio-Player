import app/pages/home
import rss_reader.{type Track}

pub fn home(tracks: List(Track)) {
  home.root(tracks)
}
