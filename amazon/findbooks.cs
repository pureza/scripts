using System;
using System.IO;
using System.Text.RegularExpressions;

public class BookFinder
{
	private static AWSECommerceService aws;
	
	public static void Main()
	{
		aws = new AWSECommerceService();
		
		Regex regexp = new Regex(@"\./(?<xiba>([^\.]+))");
		
		foreach(string file in Directory.GetFiles("./"))
		{
			MatchCollection matches = regexp.Matches(file);

			foreach(Match match in matches)
			{
				SearchForBook(match.Groups["xiba"].ToString());
			}
		}
	}
	
	public static void SearchForBook(string title)
	{
		title = title.Replace("1st", "First");
		title = title.Replace("2nd", "Second");
		title = title.Replace("3rd", "Third");
		
		Console.WriteLine("===> " + title);
		ItemSearchRequest request = new ItemSearchRequest();

		request.SearchIndex = "Books";
		request.Keywords = title;
		request.ResponseGroup = new string[] { "ItemAttributes" }; 

		ItemSearchRequest[] requests = new ItemSearchRequest[] { request };

		MessageItemSearch itemSearch = new MessageItemSearch();
		itemSearch.AWSAccessKeyId = "10XXKVYRS9C4CC4BDEG2";
		itemSearch.Request = requests;

		try		
		{
			MessageItemSearchResponse response = aws.ItemSearch(itemSearch);
			Items info = response.Items[0];
			Item[] items = info.Item;
			for (int i = 0; i < items.Length; i++)
			{
				Item item = items[i];
					
				string bookTitle = item.ItemAttributes.Title;
				
				if (bookTitle.Length > 70)
					bookTitle = title.Substring(0, 70);
		
			       Console.WriteLine("{0, -70}\t", bookTitle);
		//		Console.WriteLine("{0, -70}\t {1}", bookTitle, item.CustomerReviews.AverageRating.ToString());
			}
		}
		
		catch (Exception ex)
		{
			System.Diagnostics.Debug.WriteLine(ex.Message);
		}
		Console.WriteLine();
	}
}
